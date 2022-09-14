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

    File stops = new File('test/testdata/stops.json');
    File moves = new File('test/testdata/moves.json');
    File samplesFile = new File('test/testdata/location_samples.json');
    stops.writeAsString('');
    moves.writeAsString('');
    samplesFile.writeAsString('');

  });

  tearDown(() async {



  });

  List<LocationSample> loadDataSet( String fname) {


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

  Future<int> delay(int waitTime) async {
    await Future.delayed( Duration(milliseconds: waitTime));
    return waitTime;
  }


  Future<StreamSubscription> verify(String name, int expected ,  List<Stop> expectedStops) async{



    MobilityFeatures().stopDuration = Duration(minutes: 15);
    MobilityFeatures().placeRadius = 50.0;
    MobilityFeatures().stopRadius = 50.0;
    MobilityFeatures().mergeDuration= Duration(minutes:5);
    // MobilityFeatures()..applyMerge=false;
     MobilityFeatures().debug=true;

    controller =
        StreamController.broadcast();


    Stream<MobilityContext> mobilityStream = MobilityFeatures().contextStream;


    StreamSubscription subscription  = mobilityStream.listen(expectAsync1 ( (event) {

      print('-' * 50);

      print(
          "Mobility Context Received: ${event.toJson()}");

      print("STOPS");

      for (Stop stop in event.stops) {

        print(stop.toString());

        expect(stop.arrival.toString().substring(0,16) , anyOf(    expectedStops.map((val) => val.arrival.toString().substring(0,16)).toList()) );
        expect(stop.departure.toString().substring(0,16) , anyOf(    expectedStops.map((val) => val.departure.toString().substring(0,16)).toList()) );
      }


      print('-' * 50);



    }, max:expected, id:name) );
    await MobilityFeatures().startListening(controller.stream);
    List<LocationSample> samples = loadDataSet(name);
    for (LocationSample s in samples) {
      controller.add(s);
    }
    controller.close();



      await delay(10);

    // await MobilityFeatures().stopListening();
    return subscription;

  }



  test('verify correct stops halifax 5th sept', () async {

    var jsonTest = '[ '
        '{"geo_location":{"latitude":53.7350905734,"longitude":-1.8818817308},"place_id":0,"arrival":1662354899406,"departure":1662356935053},'
        '{"geo_location":{"latitude":53.7050630001,"longitude":-1.9143158481},"place_id":0,"arrival":1662357660999,"departure":1662362354576},'
        '{"geo_location":{"latitude":53.7350247,"longitude":-1.8819064},"place_id":1,"arrival":1662362956024,"departure":1662377706102},'
        '{"geo_location":{"latitude":53.7350921243,"longitude":-1.881882521},"place_id":1,"arrival":1662381678000,"departure":1662393538035},'
        '{"geo_location":{"latitude":53.7070989686,"longitude":-1.912036389},"place_id":2,"arrival":1662394984140,"departure":1662399701793}]';

    final List<dynamic> dataList= jsonDecode(jsonTest);

    List<Stop> _stops = [];
    for (var data in dataList) {

      Stop stop =  Stop.fromJson(data);
      _stops.add(stop);


    }

    StreamSubscription sub = await verify('Steven_Gaunt-5thsept.gpx', 5, _stops);

     sub.cancel();

  });

  test('verify correct stops buxton old trafford', () async {

    var jsonTest = '['
        '{"geo_location":{"latitude":53.251253467599994,"longitude":-1.93711104575},"place_id":0,"arrival":1662271468034,"departure":1662281928664},'
        '{"geo_location":{"latitude":53.2580651462,"longitude":-1.9166655869},"place_id":1,"arrival":1662283599000,"departure":1662285040116},'
        '{"geo_location":{"latitude":53.2512660139,"longitude":-1.9371352717},"place_id":0,"arrival":1662286111071,"departure":1662293310339},'
        '{"geo_location":{"latitude":53.46295872135,"longitude":-2.29102925835},"place_id":2,"arrival":1662301929724,"departure":1662308335002},'
        '{"geo_location":{"latitude":53.4634913388,"longitude":-2.2905782517},"place_id":3,"arrival":1662308335002,"departure":1662312403923}]';

    final List<dynamic> dataList= jsonDecode(jsonTest);
    List<Stop> _stops = [];
    for (var data in dataList) {

      Stop stop =  Stop.fromJson(data);
      _stops.add(stop);

    }
    StreamSubscription sub = await verify('Steven_Gaunt-buxt-ot.gpx', 5, _stops);
    sub.cancel();


  });




  test('verify correct stops halifax old trafford', ()  async{

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


    StreamSubscription sub = await verify('halifax_old_trafford.gpx', 7, _stops);
    sub.cancel();


  });

}
