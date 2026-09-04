import 'package:flutter/material.dart';
import 'package:identity_verification_flutter/identity_verification_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = IdentityVerification();
  String _status = '未拉起';

  Future<void> _startFaceVerify() async {
    setState(() => _status = '拉起中…');
    try {
      await _plugin.startFaceVerify(
        // 示例：替换为后端 getFaceVerifyUrl 返回的人脸 H5 地址
        h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
        // 刷脸完成后要跳转的接入方地址
        h5thirdUrl: 'qiyun://signcert/callback',
        onSuccess: (result) {
          setState(() =>
              _status = '刷脸回调 verifyId=${result.verifyId} code=${result.code}');
        },
        onMessage: (message) {
          setState(() => _status = 'H5 消息: $message');
        },
      );
    } catch (e) {
      setState(() => _status = '拉起失败: $e');
    }
  }

  Future<void> _destroyFaceVerify() async {
    await _plugin.destroy();
    if (mounted) setState(() => _status = '已关闭');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startFaceVerify,
                child: const Text('拉起 H5 刷脸'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _destroyFaceVerify,
                child: const Text('关闭 H5 刷脸'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
