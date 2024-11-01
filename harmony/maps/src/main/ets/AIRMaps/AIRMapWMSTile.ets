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
import { AIRMapWMSTileDescriptor } from './AIRMapDescriptorTypes';
import { MapsManager } from '../MapsManager';
import { LWLog } from '../LWLog';

export const AIR_WMSTILE_TYPE: string = "AIRMapWMSTile"

@Component
export struct AIRMapWMSTile {
  ctx!: RNComponentContext
  tag: number = 0
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void
  @State descriptor: AIRMapWMSTileDescriptor = {} as AIRMapWMSTileDescriptor
  private unregisterDescriptorChangesListener?: () => void = undefined

  aboutToAppear() {
    LWLog('AIRMapWMSTile.aboutToAppear 初始化 AIRMapWMSTile...')
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapWMSTileDescriptor>(this.tag)
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapWMSTileDescriptor)
      }
    )

    MapsManager.getInstance().addWMSTile(this.descriptor);
  }

  aboutToDisappear() {
    this.unregisterDescriptorChangesListener?.()
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
