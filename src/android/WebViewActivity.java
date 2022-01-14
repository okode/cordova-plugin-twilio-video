package org.apache.cordova.twiliovideo;

import android.annotation.SuppressLint;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.content.Intent;

import androidx.appcompat.app.AppCompatActivity;

public class WebViewActivity extends AppCompatActivity {

    WebView webView;
    ImageView imageView;
    ProgressBar progressBar;
    String webUrl;

    private static org.apache.cordova.twiliovideo.FakeR FAKE_R;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

       /* requestWindowFeature(Window.FEATURE_NO_TITLE); //will hide the title
        getSupportActionBar().hide(); // hide the title bar
        this.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN); //enable full screen*/

        FAKE_R = new org.apache.cordova.twiliovideo.FakeR(this);

        setContentView(FAKE_R.getLayout("activity_webview"));

        webView = findViewById(FAKE_R.getId("load_webview"));
        imageView = findViewById(FAKE_R.getId("img_close"));
        progressBar = findViewById(FAKE_R.getId("progressBar"));

        Intent intent = getIntent();

        webUrl = intent.getStringExtra("webUrl");

        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        startWebView(webView, webUrl);
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void startWebView(WebView webView, String url) {
        WebSettings settings = webView.getSettings();
        settings.setDomStorageEnabled(true);
        webView.setWebViewClient(new WebViewClient() {
            ProgressDialog progressDialog;

            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return false;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            public void onLoadResource(WebView view, String url) {


            }

            public void onPageFinished(WebView view, String url) {
                progressBar.setVisibility(View.GONE);
            }

        });

        webView.getSettings().setJavaScriptEnabled(true);
        webView.loadUrl(url);
    }
}
