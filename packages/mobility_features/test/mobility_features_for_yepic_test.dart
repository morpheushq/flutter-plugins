library mobility_test;

import 'dart:async';
import 'package:mobility_features/mobility_features.dart';

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:gpx/gpx.dart';
part 'test_utils.dart';

void main()   {

  late StreamController<LocationSample> controller ;


  setUp(() async {
   controller =
    StreamController.broadcast(sync: true);

  });

  tearDown(() async {
    controller.close();
  });

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

  Future<void> verify(String name, int expected ,  List<Stop> expectedStops) async{

    List<LocationSample> samples = loadDataSet('halifax_old_trafford.gpx');

    MobilityFeatures().stopDuration = Duration(minutes: 15);
    MobilityFeatures().placeRadius = 50.0;
    MobilityFeatures().stopRadius = 50.0;
    MobilityFeatures().mergeDuration= Duration(minutes:5);
    // MobilityFeatures()..applyMerge=false;
    // MobilityFeatures().debug=true;
    await MobilityFeatures().startListening(controller.stream);

    Stream<MobilityContext> mobilityStream = MobilityFeatures().contextStream;
    int hcode =0;
    StreamSubscription subscription  = mobilityStream.listen( expectAsync1 ( (event) {

      print('-' * 50);
      
      print(
          "${hcode} Mobility Context Received: ${event.toJson()}");

      print("STOPS");
      // print(event.stops.toString());

      for (Stop stop in event.stops) {
        
        print(stop.toString());
        print(stop.arrival.millisecondsSinceEpoch);
        print(stop.departure.millisecondsSinceEpoch);
        expect(stop.arrival.toString().substring(0,16) , anyOf(    expectedStops.map((val) => val.arrival.toString().substring(0,16)).toList()) );
        expect(stop.departure.toString().substring(0,16) , anyOf(    expectedStops.map((val) => val.departure.toString().substring(0,16)).toList()) );
      }


      print('-' * 50);

      // expect(event, value);


    },count: expected,  max: -1,id:name));
    // expectLater('2022-08-22 18:15', '2022-08-22 18:15');
    hcode =subscription.hashCode;
    for (LocationSample s in samples) {
      controller.add(s);
    }


  }



  test('verify correct stops halifax old trafford', () async {

 var jsonTest = '[{"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661149756420,"departure":1661155662081},'
      '{"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661156012000,"departure":1661166796959},'
      '{"geo_location":{"latitude":53.705293527600006,"longitude":-1.9141357615999999},"place_id":1,"arrival":1661167562000,"departure":1661172157553},'
     '{"geo_location":{"latitude":53.735097066099996,"longitude":-1.8818838867499998},"place_id":0,"arrival":1661175772993,"departure":1661175769787},'
     '{"geo_location":{"latitude":53.735097066099996,"longitude":-1.8818838867499998},"place_id":0,"arrival":1661182508232,"departure":1661182449635},'
     '{"geo_location":{"latitude":53.735097066099996,"longitude":-1.8818838867499998},"place_id":0,"arrival":1661172728998,"departure":1661184615817},'
      '{"geo_location":{"latitude":53.463130450899996,"longitude":-2.29108523105},"place_id":2,"arrival":1661192151359,"departure":1661201846111}]';
     final List<dynamic> dataList= jsonDecode(jsonTest);


      List<Stop> _stops = [];
     for (var data in dataList) {

       Stop stop =  Stop.fromJson(data);
       _stops.add(stop);


    }


     await verify('halifax_old_trafford.gpx', 5,_stops);


  });
  test('verify correct stops halifax 5th sept', () async {

    var jsonTest = '[ {"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661149756420,"departure":1661155662081},'
        '{"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661156012000,"departure":1661166796959},'
        '{"geo_location":{"latitude":53.705293527600006,"longitude":-1.9141357615999999},"place_id":1,"arrival":1661167562000,"departure":1661172157553},'
        '{"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661172728998,"departure":1661175769787},'
        '{"geo_location":{"latitude":53.7350898824,"longitude":-1.881882068},"place_id":0,"arrival":1661175772993,"departure":1661182449635},'
        '{"geo_location":{"latitude":53.7351042498,"longitude":-1.8818857055},"place_id":0,"arrival":1661182508232,"departure":1661184615817},'

        '{"geo_location":{"latitude":53.735097066099996,"longitude":-1.8818838867499998},"place_id":0,"arrival":1661172728998,"departure":1661184615817},'
        '{"geo_location":{"latitude":53.463130450899996,"longitude":-2.29108523105},"place_id":2,"arrival":1661192151359,"departure":1661201846111}]';

    final List<dynamic> dataList= jsonDecode(jsonTest);

    List<Stop> _stops = [];
    for (var data in dataList) {

      Stop stop =  Stop.fromJson(data);
      _stops.add(stop);


    }

    await verify('Steven_Gaunt-5thsept.gpx', 5,_stops);

  });



  test('verify correct stops buxton old trafford', ()async  {

    GeoLocation loc = GeoLocation(53.46295872135, -2.29102925835);
    GeoLocation loc2 = GeoLocation(53.4634913388, -2.2905782517);
    print("distance ${Distance.fromGeospatial(loc, loc2)}") ;
    List<Stop> _stops = [];
    // await verify('Steven_Gaunt-buxt-ot.gpx', 6,_stops);

  });
}
