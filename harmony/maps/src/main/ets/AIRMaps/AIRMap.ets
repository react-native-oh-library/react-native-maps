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

import { RNViewBase, Tag, RNComponentContext, ComponentBuilderContext} from '@rnoh/react-native-openharmony';

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import {map, mapCommon, MapComponent} from '@kit.MapKit'
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';

import { mapsComponentFactoryBuilder } from '../MapsComponentFactory'
import { Camera, DEFAULT_ZOOM, EdgePadding, LatLng, Region, TAG } from '../sharedTypes';
import { MapsManager } from '../MapsManager';
import { AIRMapDescriptor } from './AIRMapDescriptorTypes';
import { MapsTurboManager } from '../MapsTurboManager';
import { LWError, LWLog } from '../LWLog';
import { geoLocationManager } from '@kit.LocationKit';

export const AIR_MAP_TYPE: string = "AIRMap"

const permissions: Array<Permissions> = ['ohos.permission.INTERNET', 'ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];

@Component
export struct AIRMap {
  ctx!: RNComponentContext
  tag: number = 0
  @BuilderParam public renderChildren: () => void
  @State descriptor: AIRMapDescriptor = {} as AIRMapDescriptor
  protected cleanUpCallbacks: (() => void)[] = []
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController = undefined;
  private mapOptions?: mapCommon.MapOptions = undefined;

  aboutToAppear() {
    LWLog('AIRMap.aboutToAppear 初始化 AIRMap...')
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapDescriptor>(this.tag)
    this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapDescriptor)
        LWLog('AIRMap.subscribeToDescriptorChanges=' + JSON.stringify(newDescriptor))
      }
    ));

    this.cleanUpCallbacks.push(this.ctx.componentCommandReceiver.registerCommandCallback(
      this.tag,
      (command, args: [ESObject, ESObject, ESObject]) => {
       LWLog('AIRMap.aboutToAppear----------command=' + command, JSON.stringify(args))
        // if (command === 'animateToRegion') {
        //   this.animateToRegion(args[0] as Region, args[1] as number);
        // } else if (command === 'setCamera') {
        //   this.setCamera(args[0])
        // } else if (command === 'animateCamera') {
        //   this.animateCamera(args[0], args[1]);
        // } else if (command === 'fitToElements') {
        //   this.fitToElements(args[0], args[1]);
        // } else if (command === 'fitToSuppliedMarkers') {
        //   this.fitToSuppliedMarkers(args[0], args[1], args[2]);
        // } else if (command === 'fitToCoordinates') {
        //   this.fitToCoordinates(args[0], args[1], args[2]);
        // } else if (command === 'setMapBoundaries') {
        //   this.setMapBoundaries(args[0], args[1]);
        // } else if (command === 'setIndoorActiveLevelIndex') {
        //   this.setIndoorActiveLevelIndex(args[0]);
        // }
      }));
    LWLog('AIRMap.aboutToAppear----------descriptor.rawProps=【' + JSON.stringify(this.descriptor.rawProps) + '】')

    // 地图初始化的回调
    this.callback = async (err, _mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = _mapController;
        this.mapController.setMyLocationEnabled(this.descriptor.rawProps.showsUserLocation)
        if (this.mapController.isMyLocationEnabled()) {
          let applyResult = 0;
          //检查权限
          for (let permission of permissions) {
            let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permission);
           LWLog('AIRMap.aboutToAppear----->permission=' + permission + ' status=' + grantStatus);
            //abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
            applyResult += grantStatus;
          }
          //没有权限去申请权限
          if (applyResult !== 0) {
            applyResult = await this.reqPermissionsFromUser(permissions);
          }
          if (applyResult === 0) {
           LWLog('AIRMap.aboutToAppear----->权限申请通过')
            // 启用我的位置图层
            this.mapController?.setMyLocationEnabled(true);
            // 我的位置按钮
            this.mapController?.setMyLocationControlsEnabled(this.descriptor.rawProps.showsMyLocationButton);
            // 首次设置我的位置
            geoLocationManager.getCurrentLocation().then((result) => {
            console.log('current location: ' + JSON.stringify(result));
              // 设置用户的位置
              let position: geoLocationManager.Location = {
                "latitude": result.latitude,
                "longitude": result.longitude,
                "altitude": 0,
                "accuracy": 0,
                "speed": 0,
                "timeStamp": 0,
                "direction": 0,
                "timeSinceBoot": 0,
                //fixme 6.14 liwang新增
                "altitudeAccuracy": 0,
                "speedAccuracy": 0,
                "directionAccuracy": 0,
                "uncertaintyOfTimeSinceBoot": 0,
                "sourceType": geoLocationManager.LocationSourceType.GNSS
              };
              this.mapController?.setMyLocation(position);
              this.animateToRegion({latitude: result.latitude, longitude: result.longitude}, 500);
            });
          }
        }
        MapsManager.getInstance().initMapComponentController(this.mapController)

        //mapview
        this.mapController.on("mapLoad", () => {
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onMapReady" });
        });
        this.mapController.on("mapClick", (latLng) => {
          LWLog('AIRMap.aboutToAppear.callback.mapClick', JSON.stringify(latLng));
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onPress", coordinate: latLng });
        });
        this.mapController.on("mapLongClick", (latLng) => {
          LWLog('AIRMap.aboutToAppear.callback.mapLongClick');
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onLongPress", coordinate: latLng });
        });
        //marker
        this.mapController.on("markerClick", (marker) => {
          LWLog('AIRMap.aboutToAppear.callback.markerClick');
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onMarkerPress", coordinate: marker.getPosition() });
        });
        this.mapController.on("markerDrag", (marker) => {
          LWLog('AIRMap.aboutToAppear.callback.markerDrag');
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onMarkerDrag", coordinate: marker.getPosition() });
        });
        this.mapController.on("markerDragEnd", (marker) => {
          LWLog('AIRMap.aboutToAppear.callback.markerDragEnd');
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onMarkerDragEnd", coordinate: marker.getPosition() });
        });
        this.mapController.on("markerDragStart", (marker) => {
          LWLog('AIRMap.aboutToAppear.callback.markerDragStart');
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onMarkerDragStart", coordinate: marker.getPosition() });
        });

        this.mapController.on("cameraChange", (latLng) => {
          LWLog('AIRMap.aboutToAppear.callback.cameraChange', JSON.stringify(latLng));
          const projection: map.Projection | undefined = this.mapController?.getProjection();
          const visibleRegion: mapCommon.VisibleRegion | undefined = projection?.getVisibleRegion();
          const bounds = visibleRegion?.bounds;
          let latitudeDelta = 0;
          let longitudeDelta = 0;
          if (bounds) {
            latitudeDelta = bounds.northeast.latitude - bounds.southwest.latitude;
            longitudeDelta = bounds.northeast.longitude - bounds.southwest.longitude;
          }
          const region: Region = {
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            latitudeDelta,
            longitudeDelta
          }
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, {
            type: "onRegionChange",
            region
          });
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, {
            type: "onRegionChangeComplete",
            region
          });
        });
        this.mapController.on("cameraMove", () => {
          //LWLog('AIRMap.aboutToAppear.callback.cameraMove');
        });
        this.mapController.on("poiClick", (poi) => {
          LWLog('AIRMap.aboutToAppear.callback.poiClick', JSON.stringify(poi));
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, AIR_MAP_TYPE, { type: "onPoiClick",
            placeId: poi.id,
            name: poi.name,
            coordinate: poi.position
          });
        });
      }
    };

    this.mapOptions = {
      mapType: this.getMapType(),
      position: {
        target: {
          latitude: this.getCameraOption().center.latitude,
          longitude: this.getCameraOption().center.longitude
        },
        zoom: MapsTurboManager.getInstance().getCameraZoom(this.getCameraOption().zoom),
        tilt: 0,
        bearing: this.getCameraOption().heading
      },
      bounds: undefined,
      maxZoom: this.descriptor.rawProps.maxZoomLevel,
      minZoom: this.descriptor.rawProps.minZoomLevel,
      rotateGesturesEnabled: this.descriptor.rawProps.rotateEnabled,
      scaleControlsEnabled: this.descriptor.rawProps.showsScale,
      alwaysShowScaleEnabled: this.descriptor.rawProps.showsScale,
      scrollGesturesEnabled: this.descriptor.rawProps.scrollEnabled,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: this.descriptor.rawProps.zoomEnabled,
      zoomControlsEnabled: this.descriptor.rawProps.zoomControlEnabled,
      myLocationControlsEnabled: this.descriptor.rawProps.showsMyLocationButton,
      compassControlsEnabled: this.descriptor.rawProps.showsCompass,
      padding: {
        left: this.descriptor.rawProps.mapPadding?.left,
        top: this.descriptor.rawProps.mapPadding?.top,
        right: this.descriptor.rawProps.mapPadding?.right,
        bottom: this.descriptor.rawProps.mapPadding?.bottom
      }
    }
  }

  aboutToDisappear() {
    this.mapController?.off('mapLoad', ()=>{});
    this.mapController?.off('mapClick', ()=>{});
    this.mapController?.off('mapLongClick', ()=>{});
    this.mapController?.off('markerClick', ()=>{});
    this.mapController?.off('markerDrag', ()=>{});
    this.mapController?.off('markerDragEnd', ()=>{});
    this.mapController?.off('markerDragStart', ()=>{});
    this.mapController?.off('cameraChange', ()=>{});
    this.mapController?.off('cameraMove', ()=>{});
    this.mapController?.off('poiClick', ()=>{});
    this.cleanUpCallbacks.forEach(cb => cb())
    MapsManager.getInstance().initMapComponentController(undefined);
  }

  public animateToRegion(region: Region, duration: number) {
    let mapCamera = {
      target: { latitude: region.latitude, longitude: region.longitude },
      zoom: MapsTurboManager.getInstance().getCameraZoom(undefined),
      tilt: 0,
      bearing: 0,
    } as mapCommon.CameraPosition;
    let cameraUpdate = map.newCameraPosition(mapCamera);
    this.mapController?.animateCamera(cameraUpdate, duration);
  }

  getMapType() {
    switch (this.descriptor.rawProps.mapType) {
      case 'standard':
        return mapCommon.MapType.STANDARD;
      case 'none':
        return mapCommon.MapType.NONE;
      case 'terrain':
        return mapCommon.MapType.TERRAIN;
      default:
      //others not support
        return undefined;
    }
  }

  getCameraOption() {
    let lat: number = 39.9, lng: number = 118.9, zoom: number = DEFAULT_ZOOM;
    if (this.descriptor.rawProps.camera) {
      lat = this.descriptor.rawProps.camera.center.latitude;
      lng = this.descriptor.rawProps.camera.center.longitude;
      zoom = this.descriptor.rawProps.camera.zoom;
    } else if (this.descriptor.rawProps.initialCamera) {
      lat = this.descriptor.rawProps.initialCamera.center.latitude;
      lng = this.descriptor.rawProps.initialCamera.center.longitude;
      zoom = this.descriptor.rawProps.initialCamera.zoom;
    } else if (this.descriptor.rawProps.region) {
      lat = this.descriptor.rawProps.region.latitude;
      lng = this.descriptor.rawProps.region.longitude;
    } else if (this.descriptor.rawProps.initialRegion) {
      lat = this.descriptor.rawProps.initialRegion.latitude;
      lng = this.descriptor.rawProps.initialRegion.longitude;
    }
    return { center: {latitude: lat!!, longitude: lng}, zoom: MapsTurboManager.getInstance().getCameraZoom(zoom), pitch: 1,  heading: 1, altitude: 1} as Camera;
  }

  async reqPermissionsFromUser(permissions: Array<Permissions>): Promise<number> {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    let result = 0;
    let data = await atManager.requestPermissionsFromUser(context, permissions);
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      LWLog('AIRMap.reqPermissionsFromUser----> 权限=' + permissions[i] + ' status=' + grantStatus[i]);
      result += grantStatus[i];
    }
    return result;
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LWError(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LWError(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }

    return grantStatus;
  }

  build() {
    RNViewBase({ ctx: this.ctx, tag: this.tag}) {
      Stack() {
        // 调用MapComponent组件初始化地图
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback }).width('100%').height('100%');
        ForEach(this.descriptor.childrenTags, (tag: Tag) => {
          // this.ctx.wrappedRNChildrenBuilder.builder(this.ctx, tag)
          mapsComponentFactoryBuilder(
            this.ctx,
            tag,
            this.ctx.rnInstance.getComponentNameFromDescriptorType(this.ctx.descriptorRegistry.getDescriptor(tag)?.type))
        }, (tag: Tag) => tag.toString())
      }
    }
  }
}