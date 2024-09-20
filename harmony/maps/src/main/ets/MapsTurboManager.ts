/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { map, mapCommon, site, staticMap } from '@kit.MapKit';
import { LWError, LWLog } from './LWLog';
import {
  Address,
  Camera, ColorMap, DEFAULT_ZOOM, EdgePadding, ImageURISource, LatLng,
  Point,
  Region,
  SnapshotOptions,
  TAG } from './sharedTypes';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import { RNOHContext } from '@rnoh/react-native-openharmony/ts';

export class MapsTurboManager{

  private constructor() {
  }

  private static instance: MapsTurboManager;

  public static getInstance(): MapsTurboManager {
    if (!MapsTurboManager.instance) {
      MapsTurboManager.instance = new MapsTurboManager();
    }
    return MapsTurboManager.instance;
  }
  
  private mapController: map.MapComponentController = new map.MapComponentController();
  
  initMapComponentController(controller: map.MapComponentController){
    console.info(TAG, 'MapsTurboManager.initMapComponentController----->controller=' + controller)
    this.mapController = controller;
  }

  getMapController(){
    return this.mapController;
  }

  getCameraZoom(zoom?: number){
    if (zoom) {
      return zoom;
    }
    return DEFAULT_ZOOM;
  }

  public getCamera(){
    let cameraPosition = this.mapController.getCameraPosition();
    return {
      center: { latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude },
      zoom: cameraPosition.zoom,
      tilt: cameraPosition.tilt,
      bearing: cameraPosition.bearing,
      //rn地图中 heading 就是 bearing，RN侧获取camera时，反向填充进去返回
      heading: cameraPosition.bearing,
      //华为地图没提供这两个参数
      altitude: 0,
      pitch: 0,
    } as Camera;
  }

  public setCamera(camera: ESObject) {
    let cameraData = this.mapController?.getCameraPosition();
    let lat = cameraData?.target.latitude;
    if (camera.center && camera.center.latitude && camera.center.latitude !== 0) {
      lat = camera.center.latitude;
    }
    let lng = cameraData?.target.longitude;
    if (camera.center && camera.center.longitude && camera.center.longitude !== 0) {
      lng = camera.center.longitude;
    }
    let _zoom = cameraData?.zoom;
    if (camera.zoom && camera.zoom !== 0) {
      _zoom = camera.zoom;
    }
    let _bearing = cameraData?.bearing;
    if (camera.heading) {
      _bearing = camera.heading;
    }
    let mapCamera = {
      target: { latitude: lat, longitude: lng },
      zoom: _zoom,
      tilt: 0,
      bearing: _bearing,
    } as mapCommon.CameraPosition;
    let cameraUpdate = map.newCameraPosition(mapCamera);
    this.mapController?.moveCamera(cameraUpdate)
  }

  public animateCamera(camera: Camera, duration: number) {
    if (!camera.zoom) {
      camera.zoom = DEFAULT_ZOOM;
    }
    let cameraPosition: mapCommon.CameraPosition = {
      target: {
        latitude: camera.center.latitude,
        longitude: camera.center.longitude
      },
      zoom: this.getCameraZoom(camera.zoom),
      tilt: 0,
      bearing: camera.heading
    };
    let cameraUpdate = map.newCameraPosition(cameraPosition);
    // 以动画方式移动地图相机
    if (!cameraUpdate) {
      return;
    }
    this.mapController?.animateCamera(cameraUpdate, duration);
  }

  public animateToRegion(region: Region, duration: number) {
    let mapCamera = {
      target: { latitude: region.latitude, longitude: region.longitude },
      zoom: this.getCameraZoom(undefined),
      tilt: 0,
      bearing: 0,
    } as mapCommon.CameraPosition;
    let cameraUpdate = map.newCameraPosition(mapCamera);
    this.mapController?.animateCamera(cameraUpdate, duration);
  }

  public fitToElements(edgePadding: EdgePadding, animated: boolean) {
    //todo 对照华为地图api进行实现
  }

  public fitToSuppliedMarkers(markers: string[], edgePadding: EdgePadding, animated: boolean) {
    //todo 对照华为地图api进行实现
  }

  public fitToCoordinates(coordinates: LatLng[], edgePadding: EdgePadding, animated: boolean) {
    if (coordinates && coordinates.length > 1) {
      let bounds: mapCommon.LatLngBounds;
      if (coordinates.length == 1) {
        bounds = {
          northeast: coordinates[0],
          southwest: coordinates[1]
        };
      }else {
        bounds = {
          northeast: coordinates[0],
          southwest: coordinates[coordinates.length-1]
        };
      }
      let cameraUpdate = map.newLatLngBounds(bounds, edgePadding.top);
      if (animated) {
        this.mapController?.animateCamera(cameraUpdate);
      }else {
        this.mapController?.moveCamera(cameraUpdate);
      }
    }
  }

  public setMapBoundaries(northEast: LatLng, southWest: LatLng) {
    this.mapController?.setLatLngBounds({northeast: northEast, southwest: southWest})
  }

  getMapBoundaries() {
    try {
      let bounds = this.mapController?.getProjection().getVisibleRegion();
      let north = bounds.bounds.northeast;
      let south = bounds.bounds.southwest;
      return {
        northEast: north,
        southWest: south,
      };
    } catch (e) {
      LWError('getMapBoundaries exception=' + JSON.stringify(e));
    }
    return {};
  }

  pointForCoordinate(coordinate: LatLng) {
    try {
      let mapPoint: mapCommon.MapPoint = this.mapController?.getProjection().toScreenLocation({latitude: coordinate.latitude, longitude: coordinate.longitude});
      return {x: mapPoint?.positionX, y: mapPoint?.positionY};
    } catch (e) {
      LWError('pointForCoordinate exception=' + JSON.stringify(e));
    }
    return {};
  }

  coordinateForPoint(point: Point) {
    try {
      return this.mapController?.getProjection().fromScreenLocation({positionX: point.x, positionY: point.y});
    } catch (e) {
      LWError('coordinateForPoint exception=' + JSON.stringify(e));
    }
    return {};
  }

  public getAddressFromCoordinates(coordinate: LatLng): Promise<Address> {
    return new Promise((resolve, reject) => {
      let params: site.ReverseGeocodeParams = {
        location: {
          longitude: 10.252502,
          latitude: 43.8739168
          // longitude: coordinate.longitude,
          // latitude: coordinate.latitude
        },
        language: "zh",
        radius: 10
      };
      try {
        site.reverseGeocode(params).then((reverseGeocodeResult)=>{
          LWLog("MapsTurboManager.getAddressFromCoordinates success=" + JSON.stringify(reverseGeocodeResult));
          let address = {
            name: '',
            thoroughfare: '',
            subThoroughfare: '',
            locality: '',
            subLocality: '',
            administrativeArea: '',
            subAdministrativeArea: '',
            postalCode: '',
            countryCode: reverseGeocodeResult.addressComponent.countryCode,
            country: reverseGeocodeResult.addressComponent.countryName,
          }  as Address
          resolve(address)
        });
      } catch (err) {
        console.error(TAG, "MapsTurboManager.getAddressFromCoordinates err=" + JSON.stringify(err));
        reject(err)
      }
    });
  }

  public setIndoorActiveLevelIndex(activeLevelIndex: number) {
    //todo 暂无对应api实现
  }

  public takeSnapshot(ctx: RNOHContext, config: SnapshotOptions): Promise<string>{
    return new Promise((resolve, reject) => {
      let width = config.width;
      let height = config.height;
      let quality = config.quality * 100;
      let format = config.format === 'png' ? 'image/png' : 'image/jpg';
      const region = this.mapController.getCameraPosition().target; // 没有值时，取地图当前的中心位置
      LWLog('MapsTurboManager.takeSnapshot------>width=' + width + ' height=' + height + ' quality=' + quality + ' format=' + format);
      let option: staticMap.StaticMapOptions = {
        location: {
          latitude: config.region?.latitude ?? region.latitude,
          longitude: config.region?.longitude ?? region.longitude
        },
        zoom: DEFAULT_ZOOM,
        imageWidth: width,
        imageHeight: height,
        scale: 1,
      };
      try {
        staticMap.getMapImage(option).then(async (value) => {
          let imagePixel = value;
          if (config.result === 'file') {
            let cacheFilePath = ctx.uiAbilityContext.cacheDir + '/' + 'static_map.' + config.format;
            let cacheFileUrl = "file://" + cacheFilePath;
            await this.savePixel2File(imagePixel, cacheFilePath);
            resolve(cacheFileUrl);
          } else {
            const imagePackerApi: image.ImagePacker = image.createImagePacker();
            let packOpts: image.PackingOption = { format: format, quality: quality };
            imagePackerApi.packing(imagePixel, packOpts).then((readBuffer)=>{
              let bufferArr = new Uint8Array(readBuffer)
              let help = new util.Base64Helper
              var base = help.encodeToStringSync(bufferArr)
              base = 'data:image/jpg;base64,' + base;
              LWLog('success to create pixelmap. base64=' + base);
              resolve(base);
            });
          }
        });
      } catch (err) {
        let errInfo = "getStaticMap fail err=" + JSON.stringify(err);
        LWError(errInfo);
        reject(errInfo)
      }
    });
  }

  public getMarkersFrames(onlyVisible: Boolean) {
    //todo 华为地图不支持
    return Promise.resolve({ 'key': {} });
  }

  public async savePixel2File(pm: image.PixelMap, filePath: string){
    try {
      LWLog('保存文件路径：' + filePath + ' 文件大小：' + pm.getPixelBytesNumber());
      const imagePackerApi: image.ImagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };

      let data: ArrayBuffer = await imagePackerApi.packing(pm, packOpts);
      let file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      // /data/storage/....  加上file://前缀
      LWLog('保存文件成功，路径:' + filePath);
    } catch (err) {
      LWLog('保存文件失败，err=' + JSON.stringify(err));
    }
  }

  //marker
  public showCallout(){

  }

  public hideCallout(){

  }

  public redraw() {

  }
}