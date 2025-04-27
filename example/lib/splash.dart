import 'package:example/home.dart';
import 'package:example/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:clustering_google_maps/clustering_google_maps.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  SplashState createState() {
    return SplashState();
  }
}

class SplashState extends State<Splash> {
  final SplashBloc bloc = SplashBloc();
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Load Fake Data into Database'),
              onPressed: loading
                  ? null
                  : () async {
                      try {
                        setState(() {
                          loading = true;
                        });
                        await bloc.addFakePointsToDB(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                        setState(() {
                          loading = false;
                        });
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: Text(e.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Load Fake Data into Memory'),
              onPressed: loading
                  ? null
                  : () async {
                      try {
                        setState(() {
                          loading = true;
                        });
                        final List<LatLngAndGeohash> list =
                            await bloc.getListOfLatLngAndGeohash(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(list: list),
                          ),
                        );
                        setState(() {
                          loading = false;
                        });
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: Text(e.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
