
/**
 * This code was generated by [react-native-codegen](https://www.npmjs.com/package/react-native-codegen).
 *
 * Do not edit this file as changes may cause incorrect behavior and will be lost
 * once the code is regenerated.
 *
 * @generated by codegen project: GenerateEventEmitterH.js
 */
#pragma once

#include <react/renderer/components/view/ViewEventEmitter.h>
#include <jsi/jsi.h>

namespace facebook {
namespace react {

class Coordinate{
    public:
    double latitude;
    double longitude;
};

class Region {
public:
    double latitude;
    double longitude;
    double latitudeDelta;
    double longitudeDelta;
};

class JSI_EXPORT AIRMapEventEmitter : public ViewEventEmitter {
    public:
    using ViewEventEmitter::ViewEventEmitter;

    struct onMapReadyEvent {};
    struct onPressEvent {
        Coordinate coordinate;
    };
    struct onLongPressEvent {
        Coordinate coordinate;
    };

    struct onRegionEvent {
        Region region;
    };

    struct onPoiClickEvent {
        std::string placeId;
        std::string name;
        Coordinate coordinate;
    };

    void onMapReady(onMapReadyEvent event) const;
    void onPress(onPressEvent event) const;
    void onLongPress(onLongPressEvent event) const;
    void onRegionChange(onRegionEvent event) const;

    void onMarkerPress(onPressEvent event) const;
    void onMarkerDragStart(onPressEvent event) const;
    void onMarkerDrag(onPressEvent event) const;
    void onMarkerDragEnd(onPressEvent event) const;

    void onPoiClick(onPoiClickEvent event) const;
    
};

class JSI_EXPORT AIRMapMarkerEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;

    struct onPressEvent {};
    struct onDragEvent {
        Coordinate coordinate;
    };
    struct onDragStartEvent {
        Coordinate coordinate;
    };
    struct onDragEndEvent {
        Coordinate coordinate;
    };

    void onPress(onPressEvent event) const;
    void onDrag(onDragEvent event) const;
    void onDragStart(onDragStartEvent event) const;
    void onDragEnd(onDragEndEvent event) const;
};

class JSI_EXPORT AIRMapPolylineEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapPolygonEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapCircleEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapCalloutEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;

    struct onPressEvent {
        Coordinate coordinate;
    };
    void onPress(onPressEvent event) const;
};

class JSI_EXPORT AIRMapCalloutSubviewEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;

    struct onPressEvent {};
    void onPress(onPressEvent event) const;
};

class JSI_EXPORT GeojsonEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapUrlTileEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapWMSTileEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

class JSI_EXPORT AIRMapOverlayEventEmitter : public ViewEventEmitter {
public:
    using ViewEventEmitter::ViewEventEmitter;
};

} // namespace react
} // namespace facebook
