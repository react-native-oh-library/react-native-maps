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

export const TAG = '[liwang-native]';

export type Provider = 'google' | undefined;

export const DEFAULT_ZOOM = 12;

export type Address = {
  name: String,
  thoroughfare: String,
  subThoroughfare: String,
  locality: String,
  subLocality: String,
  administrativeArea: String,
  subAdministrativeArea: String,
  postalCode: String,
  countryCode: String,
  country: String,
};
export type MapStyleElement = {
  featureType?: string;
  elementType?: string;
  stylers: object[];
};
export type HmMapStyleElement = {
  mapFeature?: string;
  options?: string;
  visibility?: string,
  paint: object;
};
export type EdgePadding = {
  top: number;
  right: number;
  bottom: number;
  left: number;
};
export type MapType = 'hybrid' | 'mutedStandard' | 'none' | 'satellite' | 'standard' | 'terrain';
export type KmlMarker = {
  id: string;
  title: string;
  description: string;
  coordinate: LatLng;
  position: Point;
};
export type IndoorLevel = {
  index: number;
  name: string;
  shortName: string;
};
export type ActiveIndoorLevel = {
  activeLevelIndex: number;
  name: string;
  shortName: string;
};
export type IndoorBuilding = {
  underground: boolean;
  activeLevelIndex: number;
  levels: IndoorLevel[];
};

export type LatLng = {
  latitude: number;
  longitude: number;
};

export type Point = {
  x: number;
  y: number;
};

export type Region = LatLng & {
  latitudeDelta?: number;
  longitudeDelta?: number;
};

export type ImageURISource = {
  uri: string;
  scale: number;
};

export type Frame = Point & {height: number; width: number};

export type Camera = {
  /**
   * Apple Maps
   */
  altitude?: number;
  center: LatLng;
  heading: number;
  pitch: number;
  /**
   * Google Maps
   */
  zoom: number;
};

export class ColorMap{
  private static instance: ColorMap;

  public static getInstance(): ColorMap {
    if (!ColorMap.instance) {
      ColorMap.instance = new ColorMap();
    }
    return ColorMap.instance;
  }

  public colorMap = new Map<string, string>();

  constructor() {
    //Color 鸿蒙color枚举值
    this.colorMap.set("white",  "#ffffffff")
    this.colorMap.set("black",  "#ff000000")
    this.colorMap.set("blue",  "#ff0000ff")
    this.colorMap.set("brown",  "#ffa52a2a")
    this.colorMap.set("gray",  "#ff808080")
    this.colorMap.set("green", "#ff008000")
    this.colorMap.set("grey", "#ffd3d3d3")
    this.colorMap.set("orange", "#ffffa500")
    this.colorMap.set("pink", "#ffffb6c1")
    this.colorMap.set("red",    "#ffff0000")
    this.colorMap.set("yellow", "#ffffff00")
    this.colorMap.set("transparent", "#00000000")
    this.colorMap.set("springgreen", "#ff00FF7F")
    this.colorMap.set("green", "#ff008000")
    this.colorMap.set("lime", "#ff00ff00")
    this.colorMap.set("aqua", "#ff00ffff")
    this.colorMap.set("cyan", "#ff00ffff")
    this.colorMap.set("cyan", "#ff00ffff")
  }
};

export type GeoJSON = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'Point',
        coordinates: [39.9, 118.9],
      }
    }
  ]
};
export type SnapshotOptions = {
  /** optional, when omitted the view-width is used */
  width?: number;
  /** optional, when omitted the view-height is used */
  height?: number;
  /** __iOS only__, optional region to render */
  region?: Region;
  /** image formats, defaults to 'png' */
  format?: 'png' | 'jpg';
  /** image quality: 0..1 (only relevant for jpg, default: 1) */
  quality?: number;
  /** result types, defaults to 'file' */
  result?: 'file' | 'base64';
};