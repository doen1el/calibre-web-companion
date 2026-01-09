package com.vocsy.epub_viewer;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import androidx.annotation.NonNull;

public class EpubViewerPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private Reader reader;
    private ReaderConfig config;
    private MethodChannel channel;
    private static Activity activity;
    private static Context context;
    private static BinaryMessenger messenger;
    private static EventChannel eventChannel;
    private static EventChannel.EventSink sink;
    private static final String channelName = "vocsy_epub_viewer";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        messenger = binding.getBinaryMessenger();
        context = binding.getApplicationContext();

        // Event channel setup
        eventChannel = new EventChannel(messenger, "page");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                sink = eventSink;
                if (sink == null) {
                    Log.i("empty", "Sink is empty");
                }
            }

            @Override
            public void onCancel(Object o) {
                sink = null;
            }
        });

        // Method channel setup
        channel = new MethodChannel(messenger, channelName);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        messenger = null;
        context = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {}

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("setChannel")) {
            result.success(null);

        } else if (call.method.equals("setConfig")) {
            Map<String, Object> arguments = (Map<String, Object>) call.arguments;
            String identifier = arguments.get("identifier").toString();
            String themeColor = arguments.get("themeColor").toString();
            String scrollDirection = arguments.get("scrollDirection").toString();
            Boolean nightMode = Boolean.parseBoolean(arguments.get("nightMode").toString());
            Boolean allowSharing = Boolean.parseBoolean(arguments.get("allowSharing").toString());
            Boolean enableTts = Boolean.parseBoolean(arguments.get("enableTts").toString());
            config = new ReaderConfig(context, identifier, themeColor, scrollDirection, allowSharing, enableTts, nightMode);

            result.success(null);

        } else if (call.method.equals("open")) {
            Map<String, Object> arguments = (Map<String, Object>) call.arguments;
            String bookPath = arguments.get("bookPath").toString();
            String lastLocation = arguments.get("lastLocation").toString();

            reader = new Reader(context, messenger, config, sink);
            reader.open(bookPath, lastLocation);

            result.success(null);

        } else if (call.method.equals("close")) {
            if (reader != null) {
                reader.close();
            }
            result.success(null);

        } else {
            result.notImplemented();
        }
    }
}