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
import { map } from '@kit.MapKit';
import { RNComponentContext, ComponentBuilderContext } from '@rnoh/react-native-openharmony';
import { MapsManager } from '../MapsManager';
import { AIRMapClusterDescriptor } from './AIRMapDescriptorTypes';

export const AIR_MAP_CLUSTER_TYPE: string = 'AIRMapCluster';

@Component
export struct AIRMapCluster {
  ctx!: RNComponentContext;
  tag: number = 0;
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void;
  @State descriptor: AIRMapClusterDescriptor = {} as AIRMapClusterDescriptor;
  private unregisterDescriptorChangesListener?: () => void = undefined;
  private instance?: map.ClusterOverlay;

  aboutToAppear() {
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapClusterDescriptor>(this.tag);
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapClusterDescriptor);
      }
    );

    MapsManager.getInstance().addCluster(this.descriptor, this.ctx)?.then(instance => {
      this.instance = instance;
    });
  }

  aboutToDisappear() {
    this.unregisterDescriptorChangesListener?.();
    this.instance?.off('click');
    this.instance?.remove();
  }

  build() {
  }
}
