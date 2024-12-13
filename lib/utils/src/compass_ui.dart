

import 'dart:async';

import 'package:flutter/material.dart';
import '../smooth_compass.dart';
double preValue=0;
double turns=0;
///custom callback for building widget
typedef WidgetBuilder=Widget Function(BuildContext context,AsyncSnapshot<CompassModel>? compassData,Widget compassAsset);
class SmoothCompass extends StatefulWidget {
  final WidgetBuilder compassBuilder;
  final Widget? compassAsset;
  final Widget? loadingAnimation;
  final int? rotationSpeed;
  final double? height;
  final double? width;
  final ValueChanged<CompassModel>? onCompassUpdate;

  const SmoothCompass({super.key, required this.compassBuilder, this.compassAsset, this.rotationSpeed=200, this.height=200, this.width=200, this.loadingAnimation, this.onCompassUpdate});

  @override
  State<SmoothCompass> createState() => _SmoothCompassState();
}

class _SmoothCompassState extends State<SmoothCompass> {
  StreamController<CompassModel>? _stream;
  late Future<bool> availableFuture;

  @override
  void initState() {
    super.initState();
    availableFuture = Compass().isCompassAvailable();
    _stream = Compass().compassUpdates(
        interval: const Duration(milliseconds: -1,), azimuthFix: 0.0);
    if (widget.onCompassUpdate != null) {
      _stream!.stream.listen(onUpdateCompass);
    }
  }

  void onUpdateCompass(CompassModel val) {
    widget.onCompassUpdate?.call(val);
  }

  @override
  void dispose() {
    _stream?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// check if the compass support available
    return FutureBuilder(
      future: availableFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if(snapshot.connectionState==ConnectionState.waiting)
          {
            return widget.loadingAnimation != null ? widget.loadingAnimation! : const SizedBox();;
          }
        if(!snapshot.data!)
          {
            return const SizedBox();
          }
        if (_stream == null) {
          return const SizedBox();
        }
        /// start compass stream
        return StreamBuilder<CompassModel>(
          stream: _stream!.stream,
          builder: (context, AsyncSnapshot<CompassModel> snapshot) {
            if (widget.compassAsset == null) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return widget.loadingAnimation ?? const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return SizedBox();
                return Text(snapshot.error.toString());
              }
              return widget.compassBuilder(
                  context, snapshot, _defaultWidget(snapshot));
            }
            else {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return widget.loadingAnimation ?? const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return SizedBox();
                return Text(snapshot.error.toString());
              }
              return widget.compassBuilder(context, snapshot, AnimatedRotation(
                turns: snapshot.data!.turns * -1,
                duration: Duration(milliseconds: widget.rotationSpeed!),
                child: widget.compassAsset!,
              ),
              );
            }
          },
        );
      }

    );
  }

///default widget if custom widget isn't provided
  Widget _defaultWidget(AsyncSnapshot<CompassModel> snapshot)
  {
    return const SizedBox();
    return AnimatedRotation(
      turns: snapshot.data!.turns*-1,
      duration: Duration(milliseconds: widget.rotationSpeed!),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration:  const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/compass.png', package: 'smooth_compass'),
                fit: BoxFit.cover
            )
        ),
      ),
    );
  }
}


///calculating compass turn from heading value
CompassModel getCompassValues(double heading)
{
  double direction = heading;
  direction = direction < 0 ? (360 + direction): direction;


  double diff = direction - preValue;
  if(diff.abs() > 180) {
    if(preValue > direction) {
      diff = 360 - (direction-preValue).abs();
    } else {
      diff = (360 - (preValue-direction).abs()).toDouble();
      diff = diff * -1;
    }
  }

  turns += (diff / 360);
  preValue = direction;
  return CompassModel(turns: turns, angle: heading);
}
/// model to store the sensor value
class CompassModel{
  double turns;
  double angle;
  CompassModel({required this.turns,required this.angle});
}
