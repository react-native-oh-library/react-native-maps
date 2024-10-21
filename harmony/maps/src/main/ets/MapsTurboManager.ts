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
  Camera,
  DEFAULT_ZOOM,
  EdgePadding,
  LatLng,
  Point,
  Region,
  SnapshotOptions,
  TAG
} from './sharedTypes';
import { image } from '@kit.ImageKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import { RNOHContext } from '@rnoh/react-native-openharmony/ts';

export class MapsTurboManager {

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
  private calcPx2vp: Function = n => n;
  
  initMapComponentController(controller: map.MapComponentController, calc: Function) {
    console.info(TAG, 'MapsTurboManager.initMapComponentController----->controller=' + controller)
    this.mapController = controller;
    this.calcPx2vp = calc;
  }

  getMapController() {
    return this.mapController;
  }

  getCameraZoom(zoom?: number) {
    if (zoom) {
      return zoom;
    }
    return DEFAULT_ZOOM;
  }

  public getCamera() {
    const cameraPosition = this.mapController.getCameraPosition();
    return {
      center: { latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude },
      zoom: cameraPosition.zoom,
      heading: cameraPosition.bearing,
      altitude: 0, //华为地图没提供这个参数
      pitch: cameraPosition.tilt,
    } as Camera;
  }

  public setCamera(camera: ESObject) {
    const cameraData = this.mapController?.getCameraPosition();
    let lat = cameraData?.target.latitude;
    let lng = cameraData?.target.longitude;
    if (camera.center) {
      lat = camera.center.latitude;
      lng = camera.center.longitude;
    }
    const _zoom = camera.zoom || cameraData?.zoom; // 这里是大于0，不要用 ??
    const _tilt = camera.pitch ?? cameraData?.tilt;
    const _bearing = camera.heading ?? cameraData?.bearing;
    const mapCamera = {
      target: { latitude: lat, longitude: lng },
      zoom: _zoom,
      tilt: _tilt,
      bearing: _bearing,
    } as mapCommon.CameraPosition;
    const cameraUpdate = map.newCameraPosition(mapCamera);
    this.mapController?.moveCamera(cameraUpdate)
  }

  public animateCamera(camera: Camera, duration: number) {
    const cameraData = this.mapController?.getCameraPosition();
    let cameraPosition: mapCommon.CameraPosition = {
      target: {
        latitude: camera.center.latitude,
        longitude: camera.center.longitude
      },
      zoom: this.getCameraZoom(camera.zoom || cameraData.zoom),
      tilt: camera.pitch ?? cameraData.tilt,
      bearing: camera.heading ?? cameraData.bearing,
    };
    let cameraUpdate = map.newCameraPosition(cameraPosition);
    // 以动画方式移动地图相机
    if (!cameraUpdate) {
      return;
    }
    this.mapController?.animateCamera(cameraUpdate, duration);
  }

  public animateToRegion(region: Region, duration: number) {
    const cameraData = this.mapController?.getCameraPosition();
    let mapCamera = {
      target: { latitude: region.latitude, longitude: region.longitude },
      zoom: cameraData.zoom ?? this.getCameraZoom(undefined),
      tilt: cameraData.tilt,
      bearing: cameraData.bearing,
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
    if (coordinates && coordinates.length) {
      const latitudes = [];
      const longitudes = [];
      coordinates.forEach((item) => {
        latitudes.push(item.latitude);
        longitudes.push(item.longitude);
      })
      const bounds: mapCommon.LatLngBounds = {
        northeast: {
          longitude: Math.max(...longitudes),
          latitude: Math.max(...latitudes),
        },
        southwest: {
          longitude: Math.min(...longitudes),
          latitude: Math.min(...latitudes),
        },
      };
      let cameraUpdate = map.newLatLngBounds(bounds, edgePadding.top);
      if (animated) {
        this.mapController?.animateCamera(cameraUpdate);
      } else {
        this.mapController?.moveCamera(cameraUpdate);
      }
    }
  }

  public setMapBoundaries(northEast: LatLng, southWest: LatLng) {
    this.mapController?.setLatLngBounds({ northeast: northEast, southwest: southWest })
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
          longitude: coordinate.longitude,
          latitude: coordinate.latitude,
        },
        language: "zh",
        radius: 10
      };
      try {
        site.reverseGeocode(params).then((reverseGeocodeResult)=>{
          LWLog("MapsTurboManager.getAddressFromCoordinates success=" + JSON.stringify(reverseGeocodeResult));
          let address = {
            name: reverseGeocodeResult.addressDescription,
            thoroughfare: reverseGeocodeResult.addressComponent.adminLevel1,
            subThoroughfare: reverseGeocodeResult.addressComponent.adminLevel2,
            locality: reverseGeocodeResult.addressComponent.locality,
            subLocality: reverseGeocodeResult.addressComponent.subLocality1,
            administrativeArea: reverseGeocodeResult.addressComponent.adminLevel3,
            subAdministrativeArea: reverseGeocodeResult.addressComponent.adminLevel4,
            postalCode: reverseGeocodeResult.addressComponent.adminCode,
            countryCode: reverseGeocodeResult.addressComponent.countryCode,
            country: reverseGeocodeResult.addressComponent.countryName,
          }  as Address;
          resolve(address);
        });
      } catch (err) {
        console.error(TAG, "MapsTurboManager.getAddressFromCoordinates err=" + JSON.stringify(err));
        reject(err);
      }
    });
  }

  public setIndoorActiveLevelIndex(activeLevelIndex: number) {
    //todo 暂无对应api实现
  }

  /**
   * 计算两个点在屏幕上的像素距离
   * @param from 开始的点
   * @param to 结束的点
   * @returns 屏幕上的距离
   */
  public calcLength(from: mapCommon.MapPoint, to: mapCommon.MapPoint): number {
    return Math.sqrt(Math.pow(from.positionX - to.positionX, 2) + Math.pow(from.positionY - to.positionY, 2)) + 1;
  }

  public takeSnapshot(ctx: RNOHContext, config: SnapshotOptions): Promise<string> {
    return new Promise((resolve, reject) => {
      const projection = this.mapController.getProjection();
      const target = projection.getVisibleRegion().bounds;
      const view = {
        width: this.calcLength(
          projection.toScreenLocation(target.northeast),
          projection.toScreenLocation({ longitude: target.southwest.longitude, latitude: target.northeast.latitude })
        ),
        height: this.calcLength(
          projection.toScreenLocation(target.southwest),
          projection.toScreenLocation({ longitude: target.southwest.longitude, latitude: target.northeast.latitude })
        ),
      };
      let width = config.width || this.calcPx2vp(view.width);
      let height = config.height || this.calcPx2vp(view.height);
      let quality = config.quality * 100;
      let format = config.format === 'png' ? 'image/png' : 'image/jpg';
      const region = this.mapController.getCameraPosition().target; // 没有值时，取地图当前的中心位置
      LWLog('MapsTurboManager.takeSnapshot------>width=' + width + ' height=' + height + ' quality=' + quality + ' format=' + format);
      let option: staticMap.StaticMapOptions = {
        location: {
          latitude: config.region?.latitude ?? region.latitude,
          longitude: config.region?.longitude ?? region.longitude
        },
        zoom: this.mapController.getCameraPosition().zoom,
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