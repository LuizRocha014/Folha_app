package br.com.rctech.folha

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (e não FlutterActivity) é obrigatório para o plugin
// local_auth conseguir exibir o BiometricPrompt nativo. Com FlutterActivity a
// autenticação lança PlatformException(no_fragment_activity) e a digital falha
// silenciosamente.
class MainActivity : FlutterFragmentActivity()
