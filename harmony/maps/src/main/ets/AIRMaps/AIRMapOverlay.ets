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

import { ComponentBuilderContext, RNViewBase, Tag, RNComponentContext } from '@rnoh/react-native-openharmony';
import { AIRMapOverlayDescriptor } from './AIRMapDescriptorTypes';
import { MapsManager } from '../MapsManager';
import { LWLog } from '../LWLog';
import { map } from '@kit.MapKit';

export const AIR_OVERLAY_TYPE: string = "AIRMapOverlay"

@Component
export struct AIRMapOverlay {
  ctx!: RNComponentContext
  tag: number = 0
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void
  @State descriptor: AIRMapOverlayDescriptor = {} as AIRMapOverlayDescriptor
  private unregisterDescriptorChangesListener?: () => void = undefined
  private instance?: map.ImageOverlay;

  aboutToAppear() {
    LWLog('AIRMapOverlay.aboutToAppear 初始化 AIRMapOverlay...')
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapOverlayDescriptor>(this.tag)
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapOverlayDescriptor)
        this.instance?.setBounds({
          northeast: {
            latitude: this.descriptor.rawProps.bounds[0][0],
            longitude: this.descriptor.rawProps.bounds[0][1],
          },
          southwest: {
            latitude: this.descriptor.rawProps.bounds[1][0],
            longitude: this.descriptor.rawProps.bounds[1][1],
          },
        });
        this.instance?.setImage(MapsManager.getInstance().imageSourceConvert(this.descriptor.rawProps.image));
        this.instance?.setBearing(this.descriptor.rawProps.bearing);
        this.instance?.setClickable(this.descriptor.rawProps.tappable);
        this.instance?.setTransparency(1 - this.descriptor.rawProps.opacity);
      }
    )

    if (MapsManager.getInstance().isInitMapController()) {
      this.setInstance();
    } else {
      setTimeout(() => {
        this.setInstance();
      }, 500)
    }
  }

  setInstance() {
    MapsManager.getInstance().addOverlay(this.descriptor, this.ctx)?.then(instance => {
      this.instance = instance;
    });
  }

  aboutToDisappear() {
    this.unregisterDescriptorChangesListener?.();
    this.instance?.remove();
  }

  build() {
    RNViewBase({ ctx: this.ctx, tag: this.tag }) {
      Stack(){
        ForEach(this.descriptor.childrenTags, (tag: Tag) => {

        }, (tag: Tag) => tag.toString())
      }
    }
  }
}
