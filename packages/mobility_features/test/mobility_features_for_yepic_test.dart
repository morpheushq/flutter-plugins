library mobility_test;

import 'dart:async';
import 'package:mobility_features/mobility_features.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:gpx/gpx.dart';
part 'test_utils.dart';

void main()   {


  List<LocationSample> loadDataSet( String fname) {

    File stops = new File('test/testdata/stops.json');
    File moves = new File('test/testdata/moves.json');
    stops.writeAsString('');
    moves.writeAsString('');
    String datasetPath = 'test/testdata/${fname}';
    File f = new File('$datasetPath');
    String content = f.readAsStringSync();
    List<String> lines = content.split('\n');

    List<LocationSample> samples = [];

    final xmlGpx = GpxReader().fromString(content);

    xmlGpx.wpts.forEach((wpt) {
      try {

        GeoLocation geoLocation = GeoLocation(wpt.lat!, wpt.lon!);
        DateTime dateTime =  wpt.time!;
        samples.add(LocationSample(geoLocation, dateTime));
      } catch (error) {}
    });
    return samples;
  }

  Future<void> verify(String name, int expected ) async{

    List<LocationSample> samples = loadDataSet('halifax_old_trafford.gpx');
    StreamController<LocationSample> controller =
    StreamController.broadcast();
    MobilityFeatures().stopDuration = Duration(minutes: 15);
    MobilityFeatures().placeRadius = 50.0;
    MobilityFeatures().stopRadius = 50.0;
    MobilityFeatures().mergeDuration= Duration(minutes:5);
    // MobilityFeatures()..applyMerge=false;
    // MobilityFeatures().debug=true;
    await MobilityFeatures().startListening(controller.stream);

    Stream<MobilityContext> mobilityStream = MobilityFeatures().contextStream;
    mobilityStream.listen( expectAsync1 ((event) {
      print('-' * 50);
      print(
          "Mobility Context Received: ${event.toJson()}");

      print("STOPS");
      // print(event.stops.toString());
      for (Stop stop in event.stops) {
        print(stop.toString());
      }
      print('-' * 50);


    },count: expected));


    for (LocationSample s in samples) {
      controller.add(s);
    }
    controller.close();

  }



  test('verify correct stops halifax old trafford', () async {

     await verify('halifax_old_trafford.gpx', 7);


  });
  test('verify correct stops halifax 5th sept', () async {

    await verify('Steven_Gaunt-5thsept.gpx', 5);

  });



  test('verify correct stops buxton old trafford', ()  async{

    GeoLocation loc = GeoLocation(53.46295872135, -2.29102925835);
    GeoLocation loc2 = GeoLocation(53.4634913388, -2.2905782517);
    print("distance ${Distance.fromGeospatial(loc, loc2)}") ;
    await  verify('Steven_Gaunt-buxt-ot.gpx', 6);

  });
}
