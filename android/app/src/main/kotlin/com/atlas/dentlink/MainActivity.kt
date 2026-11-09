package com.atlas.dentlink

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Klavye açıkken arka plana alınınca klavye kapanır ama pencere görünmezken
    // inset değişikliği Flutter'a ulaşmaz; dönüşte eski klavye boşluğu kalır.
    // Pencere odağı geri gelince insets'i yeniden göndermek gerçek değeri iletir.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) window.decorView.requestApplyInsets()
    }
}
