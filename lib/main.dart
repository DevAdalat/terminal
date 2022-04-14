import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/flutter.dart';
import 'package:xterm/xterm.dart';

const host = 'ssh://localhost:8022';
const username = 'u0_a280';
const password = '123456';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xterm.dart demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class SSHTerminalBackend extends TerminalBackend {

  late SSHClient client;

  final String _host;

  final _exitCodeCompleter = Completer<int>();
  final _outStream = StreamController<String>();

  SSHTerminalBackend(this._host, this.sshSocket);
	SSHSocket sshSocket;
  void onWrite(String data) {
    _outStream.sink.add(data);
  }

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  void init() {
    // Use utf8.decoder to handle broken utf8 chunks
    final _sshOutput = StreamController<List<int>>();
    _sshOutput.stream.transform(utf8.decoder).listen(onWrite);
		

    onWrite('connecting $_host...');
		client = SSHClient(
				sshSocket,
				username: username,
				onPasswordRequest: () => password);
  }

  @override
  Stream<String> get out => _outStream.stream;

  @override
  void resize(int width, int height, int pixelWidth, int pixelHeight) {
  }

  @override
  void write(String input) {
		_outStream.sink.add('Disconnected');
  }

  @override
  void terminate() {
    client.close();
  }

  @override
  void ackProcessed() {
    // NOOP
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late Terminal terminal;
  late SSHTerminalBackend backend;

	Future<SSHSocket> connecting() async {
		return await SSHSocket.connect('localhost', 8022);
	}

	void setup() async {
		final socket = await connecting();
		backend = SSHTerminalBackend(host, socket );
    terminal = Terminal(backend: backend, maxLines: 10000);
	}

  @override
  void initState() {
    super.initState();
		setup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
					child: FutureBuilder(
							future: connecting(), builder: (BuildContext context, AsyncSnapshot<SSHSocket> snapshot) { 
								setup();
								if (snapshot.connectionState == ConnectionState.waiting) {
									return const Center(
											child: CircularProgressIndicator(),
									);
									
								}
								return TerminalView(terminal: terminal); 
							},
							
					)
				),
    );
  }
}
