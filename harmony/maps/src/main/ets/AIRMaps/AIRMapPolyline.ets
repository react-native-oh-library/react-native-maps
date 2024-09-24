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

import { ComponentBuilderContext, RNComponentContext } from '@rnoh/react-native-openharmony';
import { AIRMapPolylineDescriptor } from './AIRMapDescriptorTypes';
import { MapsManager } from '../MapsManager';
import { LWLog } from '../LWLog';
import { map } from '@kit.MapKit';

export const AIR_MAP_POLYLINE_TYPE: string = "AIRMapPolyline"

@Component
export struct AIRMapPolyline {
  ctx!: RNComponentContext
  tag: number = 0
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void
  @State descriptor: AIRMapPolylineDescriptor = {} as AIRMapPolylineDescriptor
  private unregisterDescriptorChangesListener?: () => void = undefined
  private instance?: map.MapPolyline;

  aboutToAppear() {
    LWLog('AIRMapPolyline.aboutToAppear 初始化 AIRMapPolyline...')
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapPolylineDescriptor>(this.tag)
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapPolylineDescriptor)
        this.instance?.setPoints(this.descriptor.rawProps.coordinates);
        this.instance?.setWidth(this.descriptor.rawProps.strokeWidth);
        this.instance?.setColor(MapsManager.getInstance().colorCovertHex(this.descriptor.rawProps.strokeColor));
        this.instance?.setColors(this.descriptor.rawProps.strokeColors.map((r) => {
          return MapsManager.getInstance().colorCovertHex(r) as number;
        }));
        this.instance?.setStartCap(MapsManager.getInstance().lineCapTypeConvert(this.descriptor.rawProps.lineCap));
        this.instance?.setEndCap(MapsManager.getInstance().lineCapTypeConvert(this.descriptor.rawProps.lineCap));
        this.instance?.setJointType(MapsManager.getInstance().lineJoinTypeConvert(this.descriptor.rawProps.lineJoin));
        this.instance?.setGeodesic(this.descriptor.rawProps.geodesic);
        this.instance?.setPatterns(MapsManager.getInstance().lineDashPatternConvert(this.descriptor.rawProps.lineDashPattern));
        this.instance?.setClickable(this.descriptor.rawProps.tappable);
        this.instance?.setZIndex(this.descriptor.rawProps.zIndex);
      }
    )

    if (MapsManager.getInstance().isInitMapController()) {
      this.setInstance();
    } else {
      setTimeout(()=>{
        this.setInstance();
      }, 500)
    }
  }

  setInstance() {
    MapsManager.getInstance().addPolyline(this.descriptor, this.ctx)?.then(instance => {
      this.instance = instance;
    });
  }

  aboutToDisappear() {
    this.unregisterDescriptorChangesListener?.();
    this.instance?.remove();
  }

  build() {
  }
}
