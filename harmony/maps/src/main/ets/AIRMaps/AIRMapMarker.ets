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

import { RNViewBase, ComponentBuilderContext, Tag, RNComponentContext } from '@rnoh/react-native-openharmony';
import { MapsManager } from '../MapsManager';
import { mapCommon, map } from '@kit.MapKit';
import { AIRMapMarkerDescriptor } from './AIRMapDescriptorTypes';
import { LWLog } from '../LWLog';

export const AIR_MAP_MARKER_TYPE: string = "AIRMapMarker"

@Component
export struct AIRMapMarker {
  ctx!: RNComponentContext
  tag: number = 0
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void
  @State descriptor: AIRMapMarkerDescriptor = {} as AIRMapMarkerDescriptor
  protected cleanUpCallbacks: (() => void)[] = []
  private marker?: map.Marker;

  aboutToAppear() {
    LWLog('AIRMapMarker.aboutToAppear 初始化 AIRMapMarker...')
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<AIRMapMarkerDescriptor>(this.tag)
    this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as AIRMapMarkerDescriptor)
        LWLog('AIRMapMarker.subscribeToDescriptorChanges=' + JSON.stringify(newDescriptor));
        this.marker?.setPosition({latitude: this.descriptor.rawProps.coordinate.latitude, longitude: this.descriptor.rawProps.coordinate.longitude})
        this.marker?.setRotation(this.descriptor.rawProps.rotation);
        this.marker?.setZIndex(this.descriptor.rawProps.zIndex);
        this.marker?.setAlpha(this.descriptor.rawProps.opacity ?? 1.0);
        this.marker?.setMarkerAnchor(MapsManager.getInstance().getPointX(this.descriptor.rawProps.anchor, 0.5), MapsManager.getInstance().getPointX(this.descriptor.rawProps.anchor, 1));
        this.marker?.setClickable(this.descriptor.rawProps.tappable===undefined?true:this.descriptor.rawProps.tappable);
        this.marker?.setDraggable(this.descriptor.rawProps.draggable===undefined?true:this.descriptor.rawProps.draggable);
        this.marker?.setIcon(MapsManager.getInstance().imageSourceConvert(this.descriptor.rawProps.image));
        this.marker?.setTitle(this.descriptor.rawProps.title);
        this.marker?.setSnippet(this.descriptor.rawProps.description);
        this.marker?.setFlat(this.descriptor.rawProps.flat);
        this.marker?.setInfoWindowAnchor(MapsManager.getInstance().getPointX(this.descriptor.rawProps.calloutAnchor, 0.5), MapsManager.getInstance().getPointX(this.descriptor.rawProps.calloutAnchor, 0));
      }
    ));
    this.cleanUpCallbacks.push(this.ctx.componentCommandReceiver.registerCommandCallback(
      this.tag,
      (command, args: [ESObject, ESObject, ESObject]) => {
       LWLog('AIRMapMarker.aboutToAppear----------command=' + command, JSON.stringify(args))
        if (command === 'showCallout') {
          this.marker?.setInfoWindowVisible(true);
        } else if (command === 'hideCallout') {
          this.marker?.setInfoWindowVisible(false);
        } else if (command === 'redrawCallout') {
          //todo 华为地图不支持 当infoWindow为自定义view的时候，调用此方法更新infoWindow里的内容
        } else if (command === 'animateMarkerToCoordinate') {
          let animation = new map.TranslateAnimation(args[0]);
          if (args.length > 1) {
            animation.setDuration(args[1]);
          }
          this.marker?.setAnimation(animation);
          this.marker?.startAnimation();
        } else if (command === 'redraw') {
          this.marker?.remove();
          this.setInstance();
        }
      }));

    if (MapsManager.getInstance().isInitMapController()) {
      this.setInstance();
    } else {
      setTimeout(()=>{
        this.setInstance();
      }, 500)
    }
  }

  setInstance() {
    MapsManager.getInstance().addMarker(this, false)?.then(instance => {
      this.marker = instance;
    });
  }

  aboutToDisappear() {
    this.cleanUpCallbacks.forEach(cb => cb());
    this.marker?.remove();
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
