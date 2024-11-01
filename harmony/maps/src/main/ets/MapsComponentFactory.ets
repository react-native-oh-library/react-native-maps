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

import {
  Descriptor,
  ComponentBuilderContext,
  Tag,
  RNComponentContext
} from '@rnoh/react-native-openharmony';
import { AIRMapCallout, AIR_MAP_CALLOUT_TYPE } from './AIRMaps/AIRMapCallout';
import { AIRMapCalloutSubview, AIR_MAP_CALLOUT_SUBVIEW_TYPE } from './AIRMaps/AIRMapCalloutSubview';
import { AIRMapCircle, AIR_MAP_CIRCLE_TYPE } from './AIRMaps/AIRMapCircle';
import { AIRMapMarker, AIR_MAP_MARKER_TYPE } from './AIRMaps/AIRMapMarker';
import { AIRMapOverlay, AIR_OVERLAY_TYPE } from './AIRMaps/AIRMapOverlay';
import { AIRMapPolygon, AIR_MAP_POLYGON_TYPE } from './AIRMaps/AIRMapPolygon';
import { AIRMapPolyline, AIR_MAP_POLYLINE_TYPE } from './AIRMaps/AIRMapPolyline';
import { AIRMapCluster, AIR_MAP_CLUSTER_TYPE } from './AIRMaps/AIRMapCluster';
import { AIRMapUrlTile, AIR_URLTILE_TYPE } from './AIRMaps/AIRMapURLTile';
import { AIRMapWMSTile, AIR_WMSTILE_TYPE } from './AIRMaps/AIRMapWMSTile';
import { AIR_GEOJSON_TYPE, Geojson } from './AIRMaps/Geojson';

export type CustomComponentBuilder = (ctx: ComponentBuilderContext) => void;

export class BuilderProxy {
  public static buildCustomComponent: CustomComponentBuilder;
}

@Component
export struct MapsComponentFactory {
  public ctx!: RNComponentContext;
  public tag: number = 0;
  @BuilderParam public buildCustomComponent!: CustomComponentBuilder;
  @State private componentName: string = '';
  @State private childrenTags: Tag[] = [];
  private cleanupCallback?: () => void = undefined;

  aboutToAppear() {
    const descriptor = this.ctx.descriptorRegistry.getDescriptor<Descriptor>(this.tag);
    if (descriptor) {
      this.setDescriptor(descriptor);
    }
    this.cleanupCallback = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(
      this.tag, (newDescriptor) => this.setDescriptor(newDescriptor)
    );
  }

  aboutToDisappear() {
    this.cleanupCallback?.();
  }

  setDescriptor(newDescriptor: Descriptor) {
    this.componentName = newDescriptor.type;
    this.childrenTags = newDescriptor.childrenTags;
  }

  build() {
    if (this.componentName === AIR_MAP_MARKER_TYPE) {
      AIRMapMarker({
        ctx: this.ctx,
        tag: this.tag,
        buildCustomComponent: this.buildCustomComponent,
      });
    } else if (this.componentName === AIR_MAP_POLYLINE_TYPE) {
      AIRMapPolyline({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_MAP_POLYGON_TYPE) {
      AIRMapPolygon({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_MAP_CIRCLE_TYPE) {
      AIRMapCircle({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_MAP_CALLOUT_TYPE) {
      AIRMapCallout({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_MAP_CALLOUT_SUBVIEW_TYPE) {
      AIRMapCalloutSubview({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_GEOJSON_TYPE) {
      Geojson({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_URLTILE_TYPE) {
      AIRMapUrlTile({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_WMSTILE_TYPE) {
      AIRMapWMSTile({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_OVERLAY_TYPE) {
      AIRMapOverlay({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else if (this.componentName === AIR_MAP_CLUSTER_TYPE) {
      AIRMapCluster({
        ctx: this.ctx,
        tag: this.tag,
      });
    } else {
    }
  }
}

@Builder
export function mapsComponentFactoryBuilder(ctx: RNComponentContext, tag: Tag, componentName: string) {
  if (componentName === AIR_MAP_MARKER_TYPE) {
    AIRMapMarker({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_MAP_POLYLINE_TYPE) {
    AIRMapPolyline({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_MAP_POLYGON_TYPE) {
    AIRMapPolygon({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_MAP_CIRCLE_TYPE) {
    AIRMapCircle({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_MAP_CALLOUT_TYPE) {
    AIRMapCallout({
      ctx: ctx,
      tag: tag,

    });
  } else if (componentName === AIR_MAP_CALLOUT_SUBVIEW_TYPE) {
    AIRMapCalloutSubview({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_GEOJSON_TYPE) {
    Geojson({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_URLTILE_TYPE) {
    AIRMapUrlTile({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_WMSTILE_TYPE) {
    AIRMapWMSTile({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_OVERLAY_TYPE) {
    AIRMapOverlay({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName === AIR_MAP_CLUSTER_TYPE) {
    AIRMapCluster({
      ctx: ctx,
      tag: tag,
      buildCustomComponent: BuilderProxy.buildCustomComponent,
    });
  } else if (componentName !== '') {
    ctx.wrappedRNChildrenBuilder.builder(ctx, tag);
    // RNComponentFactory({ ctx: ctx, tag: tag, buildCustomComponent: BuilderProxy.buildCustomComponent })
  } else {
  }
}