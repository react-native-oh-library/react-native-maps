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

import { TurboModule, RNOHError, RNOHContext } from '@rnoh/react-native-openharmony/ts';
import { MapsTurboManager } from '../MapsTurboManager';
import { Camera, EdgePadding, LatLng, Point, Region, SnapshotOptions, TAG } from '../sharedTypes';

export class AIRMapManager extends TurboModule {
  // constructor(ctx: RNOHContext) {
  //   super(ctx);
  //   MapsTurboManager.getInstance().
  //   ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
  //     (newDescriptor) => {
  //
  //       this.descriptor = (newDescriptor as AIRMapDescriptor)
  //       LWLog('AIRMap.subscribeToDescriptorChanges=' + JSON.stringify(newDescriptor))
  //     }
  //   )
  // }

  public __onDestroy__(): void {
  }



  /**
   * Like animateCamera, but sets the new view instantly, without an animation.
   *
   * @param camera
   */
  public setCamera(camera: Camera){
    MapsTurboManager.getInstance().setCamera(camera);
  }

  /**
   * Returns a Promise<Camera> structure indicating the current camera configuration.
   *
   * @returns
   */
  public getCamera(){
    let camera = MapsTurboManager.getInstance().getCamera();
    return camera;
  }

  /**
   * Takes a snapshot of the map and saves it to a picture file or returns the image as a base64 encoded string
   *
   * @param config Configuration options
   * @returns Promise Promise with either the file-uri or base64 encoded string
   */
  public takeSnapshot(config: SnapshotOptions): Promise<string>{
    return MapsTurboManager.getInstance().takeSnapshot(this.ctx, config);
  }

  /**
   * Get visible boudaries
   *
   * @return Promise Promise with the bounding box ({ northEast: <LatLng>, southWest: <LatLng> })
   */
  public getMapBoundaries(){
    return MapsTurboManager.getInstance().getMapBoundaries();
  }

  /**
   * Convert a coordinate to address by using default Geocoder
   *
   * @param coordinate Coordinate
   * @param [coordinate.latitude] Latitude
   * @param [coordinate.longitude] Longitude
   *
   * @return Promise with return type Address
   */
  public getAddressFromCoordinates(coordinate: LatLng){
    return MapsTurboManager.getInstance().getAddressFromCoordinates(coordinate);
  }

  /**
   * Convert a map coordinate to user-space point
   *
   * @param coordinate Coordinate
   * @param [coordinate.latitude] Latitude
   * @param [coordinate.longitude] Longitude
   *
   * @return Promise Promise with the point ({ x: Number, y: Number })
   */
  public pointForCoordinate(coordinate: LatLng){
    return MapsTurboManager.getInstance().pointForCoordinate(coordinate);
  }

  /**
   * Convert a user-space point to a map coordinate
   *
   * @param point Point
   * @param [point.x] X
   * @param [point.x] Y
   *
   * @return Promise Promise with the coordinate ({ latitude: Number, longitude: Number })
   */
  public coordinateForPoint(point: Point){
    return MapsTurboManager.getInstance().coordinateForPoint(point);
  }

  /**
   * Get markers' centers and frames in user-space coordinates
   *
   * @param onlyVisible boolean true to include only visible markers, false to include all
   *
   * @return Promise Promise with { <identifier>: { point: Point, frame: Frame } }
   */
  public getMarkersFrames(onlyVisible: Boolean){
    //todo 华为地图不支持
    return MapsTurboManager.getInstance().getMarkersFrames(onlyVisible);
  }

  public animateToRegion(region: Region, duration: number) {
    MapsTurboManager.getInstance().animateToRegion(region, duration);
  }

  /**
   * Animate the camera to a new view. You can pass a partial camera object here; any property not given will remain unmodified.
   *
   * @param camera
   * @param duration
   */
  public animateCamera(camera: Camera, duration: number) {
    MapsTurboManager.getInstance().animateCamera(camera, duration);
  }

  /**
   * Note edgePadding is Google Maps only
   *
   * @param edgePadding
   * @param animated
   */
  public fitToElements(edgePadding: EdgePadding, animated: boolean) {
    //todo 华为地图不支持 地图加载kml数据后的操作
  }

  /**
   * If you need to use this in ComponentDidMount, make sure you put it in a timeout or it will cause performance problems. Note edgePadding is Google Maps only
   *
   * @param markers
   * @param edgePadding
   * @param animated
   */
  public fitToSuppliedMarkers(markers: string[], edgePadding: EdgePadding, animated: boolean) {
    //todo 华为地图不支持
  }

  /**
   * If called in ComponentDidMount in android, it will cause an exception. It is recommended to call it from the MapView onLayout event.
   *
   * @param coordinates
   * @param edgePadding
   * @param animated
   */
  public fitToCoordinates(coordinates: LatLng[], edgePadding: EdgePadding, animated: boolean) {
    MapsTurboManager.getInstance().fitToCoordinates(coordinates, edgePadding, animated);
  }

  /**
   * 	The boundary is defined by the map's center coordinates, not the device's viewport itself. Note: Google Maps only.
   *
   * @param northEast
   * @param southWest
   */
  public setMapBoundaries(northEast: LatLng, southWest: LatLng) {
    MapsTurboManager.getInstance().setMapBoundaries(northEast, southWest)
  }

  public setIndoorActiveLevelIndex(activeLevelIndex: number) {
    //todo 华为地图不支持
  }
}
