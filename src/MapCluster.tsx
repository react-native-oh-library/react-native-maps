import * as React from 'react';
import { NativeSyntheticEvent, StyleSheet, ViewProps, View } from 'react-native';
import decorateMapComponent, {
  MapManagerCommand,
  NativeComponent,
  ProviderContext,
  SUPPORTED,
  UIManagerCommand,
  USES_DEFAULT_IMPLEMENTATION,
} from './decorateMapComponent';
import { LatLng, Point } from './sharedTypes';

export type MapClusterProps = ViewProps & {
  /**
   * 聚合节点聚合的距离
   */
  distance: number;

  /**
   * 待聚合节点数组
   */
  clusterItems: Array<{ position: LatLng }>;

  /**
   * Callback that is called when the user presses on the overlay
   */
  onPress?: (event: ClusterPressEvent) => void;
};

type NativeProps = MapClusterProps;

export class MapCluster extends React.Component<MapClusterProps> {
  // declaration only, as they are set through decorateMap
  declare context: React.ContextType<typeof ProviderContext>;
  getNativeComponent!: () => NativeComponent<NativeProps>;
  getMapManagerCommand!: (name: string) => MapManagerCommand;
  getUIManagerCommand!: (name: string) => UIManagerCommand;

  render() {
    const AIRMapCluster = this.getNativeComponent();

    return (
      <AIRMapCluster
        {...this.props}
        style={[styles.cluster, this.props.style]}
        onPress={event => {
          if (this.props.onPress) {
            this.props.onPress(event);
          }
        }}
      />
    );
  }
}

const styles = StyleSheet.create({
  cluster: {
    position: 'absolute',
    backgroundColor: 'transparent',
  },
});

type ClusterPressEvent = NativeSyntheticEvent<{
  action: 'cluster-press';
  points: string;
  id?: string;
}>;

export default decorateMapComponent(MapCluster, 'Cluster', {
  google: {
    ios: SUPPORTED,
    android: USES_DEFAULT_IMPLEMENTATION,
  },
});
