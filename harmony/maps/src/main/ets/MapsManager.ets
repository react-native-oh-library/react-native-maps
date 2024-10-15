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

import { map, mapCommon } from '@kit.MapKit';
import { RNComponentContext } from '@rnoh/react-native-openharmony';
import { AIRMapCallout, AIR_MAP_CALLOUT_TYPE } from './AIRMaps/AIRMapCallout';
import { AIR_MAP_CIRCLE_TYPE } from './AIRMaps/AIRMapCircle';
import {  AIRMapMarkerDescriptor,
  AIRMapPolylineDescriptor,
  AIRMapPolygonDescriptor,
  AIRMapCircleDescriptor,
  AIRMapCalloutDescriptor,
  AIRMapCalloutSubviewDescriptor,
  GeojsonDescriptor,
  AIRMapWMSTileDescriptor,
  AIRMapUrlTileDescriptor,
  AIRMapOverlayDescriptor
} from './AIRMaps/AIRMapDescriptorTypes';
import { AIRMapMarker, AIR_MAP_MARKER_TYPE } from './AIRMaps/AIRMapMarker';
import { AIR_OVERLAY_TYPE } from './AIRMaps/AIRMapOverlay';
import { AIR_MAP_POLYGON_TYPE } from './AIRMaps/AIRMapPolygon';
import { AIR_MAP_POLYLINE_TYPE } from './AIRMaps/AIRMapPolyline';
import { LWError, LWLog } from './LWLog';
import { MapsTurboManager } from './MapsTurboManager';
import { ColorMap, Point } from './sharedTypes';

export class MapsManager {
  private constructor() {
  }

  private static instance: MapsManager;

  public static getInstance(): MapsManager {
    if (!MapsManager.instance) {
      MapsManager.instance = new MapsManager();
    }
    return MapsManager.instance;
  }
  
  private mapController?: map.MapComponentController;
  private initMapController = false;
  private eventNodeMap: Map<string, number> = new Map();
  
  initMapComponentController(controller?: map.MapComponentController) {
    LWLog('MapsManager.initMapComponentController----->controller=' + controller)
    if (!controller) {
      //释放controller
      if (this.mapController) {
        this.eventNodeMap.clear();
        this.mapController?.off('markerClick', () => {});
        this.mapController?.off('markerDragStart', () => {});
        this.mapController?.off('markerDrag', () => {});
        this.mapController?.off('markerDragEnd', () => {});
        this.mapController?.off('infoWindowClick', () => {});
        this.mapController?.off('polylineClick', () => {});
        this.mapController?.off('polygonClick', () => {});
        this.mapController?.off('circleClick', () => {});
        this.mapController?.off('imageOverlayClick', () => {});
      }
    }
    this.mapController = controller;
    MapsTurboManager.getInstance().initMapComponentController(this.mapController, (n: number) => px2vp(n));
    this.initMapController = this.mapController?true:false;
  }

  isInitMapController(){
    return this.initMapController;
  }

  // addMarker(desc: AIRMapMarkerDescriptor, clear: boolean, markerEventCallback: Function){
  addMarker(_this: AIRMapMarker, clear: boolean) {
    LWLog('MapsManager.addMarker----->rawProps=【' + JSON.stringify(_this.descriptor.rawProps) + '】')
    if (!this.mapController) {
      LWError('addMarker error, mapController is undefined!')
      return;
    }
    let desc: AIRMapMarkerDescriptor = _this.descriptor;
    if (clear) {
      //map api中没有清除marker，只能用clear
      this.mapController.clear();
    }
    let markerOptions: mapCommon.MarkerOptions = {
      position: {
        latitude: desc.rawProps.coordinate.latitude,
        longitude: desc.rawProps.coordinate.longitude
      },
      rotation: desc.rawProps.rotation,
      icon: this.imageSourceConvert(desc.rawProps.image),
      alpha: desc.rawProps.opacity ?? 1.0,
      anchorU: this.getPointX(desc.rawProps.anchor, 0.5),
      anchorV: this.getPointY(desc.rawProps.anchor, 1),
      clickable: desc.rawProps.tappable === undefined ? true : desc.rawProps.tappable,
      draggable: desc.rawProps.draggable,
      flat: desc.rawProps.flat,
      title: desc.rawProps.title,
      snippet: desc.rawProps.description,
      infoWindowAnchorU: this.getPointX(desc.rawProps.calloutAnchor, 0.5),
      infoWindowAnchorV: this.getPointY(desc.rawProps.calloutAnchor, 0),
      zIndex: desc.rawProps.zIndex,
      visible: true,
    };
    return this.mapController.addMarker(markerOptions).then(marker => {
      LWLog('MapsManager.addMarker----------marker=' + marker.getId())
      this.eventNodeMap.set(marker.getId(), desc.tag);
      this.mapController?.on("markerClick", (marker) => {
        _this.ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(marker.getId()), AIR_MAP_MARKER_TYPE, { type: "onPress" });
        if (marker.getTitle()) {
          marker.setInfoWindowVisible(!marker.isInfoWindowVisible());
        }
      })
      this.mapController?.on("markerDragStart", (marker) => {
        _this.ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(marker.getId()), AIR_MAP_MARKER_TYPE, { type: "onDragStart", coordinate: marker.getPosition() });
      })
      this.mapController?.on("markerDrag", (marker) => {
        _this.ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(marker.getId()), AIR_MAP_MARKER_TYPE, { type: "onDrag", coordinate: marker.getPosition() });
      })
      this.mapController?.on("markerDragEnd", (marker) => {
        _this.ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(marker.getId()), AIR_MAP_MARKER_TYPE, { type: "onDragEnd", coordinate: marker.getPosition()  });
      })
      return marker;
    });
  }

  addPolyline(desc: AIRMapPolylineDescriptor, ctx: RNComponentContext) {
    LWLog('MapsManager.addPolyline----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
    if (!this.mapController) {
      LWError('addPolyline error, mapController is undefined!')
      return;
    }
    let polylineOption: mapCommon.MapPolylineOptions = {
      points: desc.rawProps.coordinates,
      clickable: desc.rawProps.tappable,
      color: this.colorCovertHex(desc.rawProps.strokeColor, 0XFF000000),
      colors: desc.rawProps.strokeColors?.map((color, i): number => { return this.colorCovertHex(color) }),
      startCap: this.lineCapTypeConvert(desc.rawProps.lineCap),
      endCap: this.lineCapTypeConvert(desc.rawProps.lineCap),
      geodesic: desc.rawProps.geodesic,
      jointType: this.lineJoinTypeConvert(desc.rawProps.lineJoin),
      patterns: this.lineDashPatternConvert(desc.rawProps.lineDashPattern),
      width: desc.rawProps.strokeWidth,
      gradient: false,
      visible: true,
      zIndex: desc.rawProps.zIndex,
    }
    // 创建polyline
    return this.mapController.addPolyline(polylineOption).then(mapPolyline => {
      LWLog('MapsManager.addPolyline----------polyline=' + mapPolyline)
      this.eventNodeMap.set(mapPolyline.getId(), desc.tag);
      this.mapController?.on("polylineClick", (polyline) => {
        ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(polyline.getId()), AIR_MAP_POLYLINE_TYPE, { type: "onPress" });
      })
      return mapPolyline;
    });
  }

  addPolygon(desc: AIRMapPolygonDescriptor, ctx: RNComponentContext) {
    LWLog('MapsManager.addPolygon----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
    if (!this.mapController) {
      LWError('addPolygon error, mapController is undefined!')
      return;
    }
    let polygonOptions: mapCommon.MapPolygonOptions = {
      points: desc.rawProps.coordinates,
      holes: desc.rawProps.holes,
      clickable: desc.rawProps.tappable,
      fillColor: this.colorCovertHex(desc.rawProps.fillColor, 0XFF000000),
      geodesic: desc.rawProps.geodesic,
      strokeColor: this.colorCovertHex(desc.rawProps.strokeColor, 0XFF000000),
      jointType: this.lineJoinTypeConvert(desc.rawProps.lineJoin),
      patterns: this.lineDashPatternConvert(desc.rawProps.lineDashPattern),
      strokeWidth: desc.rawProps.strokeWidth,
      visible: true,
      zIndex: desc.rawProps.zIndex,
    }
    // 创建多边形
    return this.mapController.addPolygon(polygonOptions).then(mapPolygon => {
      LWLog('MapsManager.addPolygon----------polygon=' + mapPolygon)
      this.eventNodeMap.set(mapPolygon.getId(), desc.tag);
      this.mapController?.on("polygonClick", (polygon) => {
        ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(polygon.getId()), AIR_MAP_POLYGON_TYPE, { type: "onPress" });
      })
      return mapPolygon;
    });
  }

  addCircle(desc: AIRMapCircleDescriptor, ctx: RNComponentContext) {
    LWLog('MapsManager.addCircle----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
    if (!this.mapController) {
      LWError('addCircle error, mapController is undefined!')
      return;
    }
    let mapCircleOptions: mapCommon.MapCircleOptions = {
      center: {
        latitude: desc.rawProps.center.latitude,
        longitude: desc.rawProps.center.longitude
      },
      radius: desc.rawProps.radius,
      clickable: true,
      fillColor: this.colorCovertHex(desc.rawProps.fillColor, 0XFF000000),
      strokeColor: this.colorCovertHex(desc.rawProps.strokeColor, 0XFF000000),
      patterns: this.lineDashPatternConvert(desc.rawProps.lineDashPattern),
      strokeWidth: desc.rawProps.strokeWidth,
      visible: true,
      zIndex: desc.rawProps.zIndex,
    }
    // 创建Circle
    return this.mapController.addCircle(mapCircleOptions).then(mapCircle => {
      LWLog('MapsManager.addCircle----------circle=' + JSON.stringify(mapCircle));
      this.eventNodeMap.set(mapCircle.getId(), desc.tag);
      this.mapController?.on("circleClick", (circle) => {
        ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(circle.getId()), AIR_MAP_CIRCLE_TYPE, { type: "onPress" });
      })
      return mapCircle;
    });
  }

  addCallout(_this: AIRMapCallout) {
    let desc = _this.descriptor;
    LWLog('MapsManager.addCallout----marker不自带callout显示，自定义ui实现？------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
    if (!this.mapController) {
      LWError('addCallout error, mapController is undefined!')
      return;
    }
    try {
      this.mapController.on("infoWindowClick", (marker) => {
        _this.ctx.rnInstance.emitComponentEvent(_this.descriptor.tag, AIR_MAP_CALLOUT_TYPE, { type: "onPress", coordinate: marker.getPosition() });
      })
    } catch (err) {
      LWError(JSON.stringify(err));
    }
  }

  addCalloutSubview(desc: AIRMapCalloutSubviewDescriptor) {
    LWLog('MapsManager.addCalloutSubview----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
  }

  addGeojson(desc: GeojsonDescriptor) {
    LWLog('MapsManager.addGeojson----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
  }

  addURLTile(desc: AIRMapUrlTileDescriptor) {
    LWLog('MapsManager.addURLTile----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
  }

  addWMSTile(desc: AIRMapWMSTileDescriptor) {
    LWLog('MapsManager.addWMSTile----------rawProps=【' + JSON.stringify(desc.rawProps) + '】')
  }

  addOverlay(desc: AIRMapOverlayDescriptor, ctx: RNComponentContext) {
    LWLog('MapsManager.addOverlay----------rawProps=【' + JSON.stringify(desc.rawProps) + '】');
    if (!this.mapController) {
      LWError('addCircle error, mapController is undefined!')
      return;
    }
    let mapImageOptions: mapCommon.ImageOverlayParams = {
      bounds: {
        northeast: {
          latitude: desc.rawProps.bounds[0][0],
          longitude: desc.rawProps.bounds[0][1],
        },
        southwest: {
          latitude: desc.rawProps.bounds[1][0],
          longitude: desc.rawProps.bounds[1][1],
        },
      },
      bearing: desc.rawProps.bearing,
      clickable: desc.rawProps.tappable,
      image: this.imageSourceConvert(desc.rawProps.image) as string, // TODO http图片待配置，这里只配了本地图片
      transparency: 1 - desc.rawProps.opacity,
    }
    // 创建Overlay
    return this.mapController.addImageOverlay(mapImageOptions).then(mapImage => {
      LWLog('MapsManager.addImageOverlay----------image=' + JSON.stringify(mapImage));
      this.eventNodeMap.set(mapImage.getId(), desc.tag);
      this.mapController?.on("imageOverlayClick", (image) => {
        ctx.rnInstance.emitComponentEvent(this.eventNodeMap.get(image.getId()), AIR_OVERLAY_TYPE, { type: "onPress" });
      });
      return mapImage;
    });
  }

  colorCovertHex(color: string, defaultValue?: number) {
    let colorResult: number = defaultValue ?? 0XFF000000;
    if (color) {
      color = color.toLowerCase().trim();
      if (color.startsWith('rgba') || color.startsWith('rgb')) {
        //rgba(0, 255, 255, 0.5)  rgb(255, 255, 255)
        let strHex: ESObject = "";
        let colorArr = color.replace(/(?:\(|\)|rgba|rgb)*/g, "").split(",");
        let hex = '';
        //补全透明度
        if (colorArr.length == 3) {
          colorArr.push('1');
        }
        let transHex = '';
        LWLog('颜色转换值 rgb colorArr=' + colorArr);
        // 转成16进制
        for (let i = 0; i < colorArr.length; i++) {
          if (i === colorArr.length - 1) {
            transHex = Math.round(Number(colorArr[i])*255).toString(16);
          }else {
            hex = Number(colorArr[i]).toString(16);
            if (hex === "0") {
              hex += hex;
            }
            strHex += hex;
          }
        }
        strHex = '0x' + transHex + strHex;
        LWLog('颜色转换值 rgb strHex=' + strHex);
        colorResult = strHex as number;
      } else if (color.startsWith('#')) {
        if (color.length === 4) {
          color = color.slice(1);
          let fullColor = '#ff';
          for (let i = 0; i < color.length; i++) {
            fullColor += `${color[i]}${color[i]}`; // 重复每个字符两次得到完整的颜色值
          }
          color = fullColor;
        }
        if (color.length === 7) {
          color = '#ff' + color.substring(1);
        }
        colorResult = parseInt(color.slice(1), 16);
      } else {
        let colorKey = color.toLowerCase();
        if (ColorMap.getInstance().colorMap.has(colorKey)) {
          colorResult = parseInt(ColorMap.getInstance().colorMap.get(colorKey)!!.slice(1), 16);
        } else {
          LWError('unsupport color');
        }
      }
    }
    LWLog('颜色转换值 colorResult=' + colorResult);
    return colorResult;
  }

  lineDashPatternConvert(target: number[]) {
    if (target && target.length > 0) {
      let result = new Array<mapCommon.PatternItem>();
      const source = target.length % 2 === 0 ? target : [...target, ...target];
      source.forEach((element, index) => {
        if (index % 2 === 0) {
          result.push({ type: mapCommon.PatternItemType.DASH, length: element });
        } else {
          result.push({ type: mapCommon.PatternItemType.GAP, length: element });
        }
      });
      return result;
    }
    return [];
  }

  imageSourceConvert(target: string) {
    //asset://examples_maps_assets_flagblue.png 对应到鸿蒙侧规则：所在文件夹名字下划线分割_替换-的图片名
    LWLog('MapsManager.imageSourceConvert.target=' + target);
    if (target && target.startsWith("asset://")) {
      return target.replace("asset://", "assets/");
    }
    return undefined;
  }

  lineJoinTypeConvert(target?: string) {
    switch (target?.toLowerCase()){
      case 'miter':
        return mapCommon.JointType.DEFAULT;
      case 'round':
        return mapCommon.JointType.ROUND;
      case 'bevel':
        return mapCommon.JointType.BEVEL;
      default:
        return mapCommon.JointType.DEFAULT;
    }
  }

  lineCapTypeConvert(target?: string) {
    switch (target?.toLowerCase()){
      case 'butt':
        return mapCommon.CapStyle.BUTT;
      case 'round':
        return mapCommon.CapStyle.ROUND;
      case 'square':
        return mapCommon.CapStyle.SQUARE;
      default:
        return mapCommon.CapStyle.BUTT;
    }
  }

  public getPointX(target: Point, defaultValue: number) {
    if (target && target.x) {
      return target.x;
    }
    return defaultValue;
  }

  getPointY(target: Point, defaultValue: number) {
    if (target && target.y) {
      return target.y;
    }
    return defaultValue;
  }
}