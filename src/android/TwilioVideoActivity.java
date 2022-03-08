package org.apache.cordova.twiliovideo;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.media.AudioManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.twilio.audioswitch.AudioDevice;
import com.twilio.audioswitch.AudioSwitch;
import com.twilio.video.ConnectOptions;
import com.twilio.video.LocalAudioTrack;
import com.twilio.video.LocalParticipant;
import com.twilio.video.LocalVideoTrack;
import com.twilio.video.RemoteAudioTrack;
import com.twilio.video.RemoteAudioTrackPublication;
import com.twilio.video.RemoteDataTrack;
import com.twilio.video.RemoteDataTrackPublication;
import com.twilio.video.RemoteParticipant;
import com.twilio.video.RemoteVideoTrack;
import com.twilio.video.RemoteVideoTrackPublication;
import com.twilio.video.Room;
import com.twilio.video.TwilioException;
import com.twilio.video.Video;
import com.twilio.video.VideoTrack;
import com.twilio.video.VideoView;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import kotlin.Unit;
import kotlin.jvm.functions.Function2;

import static org.apache.cordova.twiliovideo.CallEventId.CLOSED;
import static org.apache.cordova.twiliovideo.CallEventId.CONNECTED;
import static org.apache.cordova.twiliovideo.CallEventId.CONNECT_FAILURE;
import static org.apache.cordova.twiliovideo.CallEventId.DISCONNECTED;
import static org.apache.cordova.twiliovideo.CallEventId.DISCONNECTED_WITH_ERROR;
import static org.apache.cordova.twiliovideo.CallEventId.HANG_UP;
import static org.apache.cordova.twiliovideo.CallEventId.OPENED;
import static org.apache.cordova.twiliovideo.CallEventId.PARTICIPANT_CONNECTED;
import static org.apache.cordova.twiliovideo.CallEventId.PARTICIPANT_DISCONNECTED;
import static org.apache.cordova.twiliovideo.CallEventId.PERMISSIONS_REQUIRED;
import static org.apache.cordova.twiliovideo.CallEventId.RECONNECTED;
import static org.apache.cordova.twiliovideo.CallEventId.RECONNECTING;
import static org.apache.cordova.twiliovideo.CallEventId.REMOTE_VIDEO_TRACK_ADDED;
import static org.apache.cordova.twiliovideo.CallEventId.REMOTE_VIDEO_TRACK_REMOVED;

public class TwilioVideoActivity extends AppCompatActivity implements CallActionObserver, AudioManager.OnAudioFocusChangeListener {

    /*
     * Audio and video tracks can be created with names. This feature is useful for categorizing
     * tracks of participants. For example, if one participant publishes a video track with
     * ScreenCapturer and CameraCapturer with the names "screen" and "camera" respectively then
     * other participants can use RemoteVideoTrack#getName to determine which video track is
     * produced from the other participant's screen or camera.
     */
    private static final String LOCAL_AUDIO_TRACK_NAME = "microphone";
    private static final String LOCAL_VIDEO_TRACK_NAME = "camera";

    private static final boolean IS_AUDIO_LOGGING_ENABLED = false;
    private static final List<Class<? extends AudioDevice>> PREFERRED_AUDIO_DEVICE_LIST =
        Arrays.asList(
            AudioDevice.BluetoothHeadset.class,
            AudioDevice.WiredHeadset.class,
            AudioDevice.Speakerphone.class
        );

    private static final int PERMISSIONS_REQUEST_CODE = 1;

    private static FakeR FAKE_R;

    /*
     * Access token used to connect. This field will be set either from the console generated token
     * or the request to the token server.
     */
    private String accessToken;
    private String roomId;
    private CallConfig config;

    /*
     * A Room represents communication between a local participant and one or more participants.
     */
    private static Room room;
    private LocalParticipant localParticipant;

    /*
     * A VideoView receives frames from a local or remote video track and renders them
     * to an associated view.
     */
    private VideoView primaryVideoView;
    private VideoView thumbnailVideoView;

    /*
     * Android application UI elements
     */
    private CameraCapturerCompat cameraCapturer;
    private LocalAudioTrack localAudioTrack;
    private LocalVideoTrack localVideoTrack;
    private FloatingActionButton connectActionFab;
    private FloatingActionButton switchCameraActionFab;
    private FloatingActionButton localVideoActionFab;
    private FloatingActionButton muteActionFab;
    private FloatingActionButton switchAudioActionFab;
    private String remoteParticipantIdentity;

    /*
     * Audio management
     */
    private AudioSwitch audioSwitch;
    private int savedVolumeControlStream;

    private boolean disconnectedFromOnDestroy;

    public static Room getVideocallRoomInstance() {
        return room;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TwilioVideoManager.getInstance().setActionListenerObserver(this);

        FAKE_R = new FakeR(this);

        publishEvent(CallEvent.of(OPENED));
        setContentView(FAKE_R.getLayout("activity_video"));

        primaryVideoView = findViewById(FAKE_R.getId("primary_video_view"));
        thumbnailVideoView = findViewById(FAKE_R.getId("thumbnail_video_view"));

        connectActionFab = findViewById(FAKE_R.getId("connect_action_fab"));
        switchCameraActionFab = findViewById(FAKE_R.getId("switch_camera_action_fab"));
        localVideoActionFab = findViewById(FAKE_R.getId("local_video_action_fab"));
        muteActionFab = findViewById(FAKE_R.getId("mute_action_fab"));
        switchAudioActionFab = findViewById(FAKE_R.getId("switch_audio_action_fab"));

        /*
         * Setup audio management and set the volume control stream
         */
        audioSwitch = new AudioSwitch(
            getApplicationContext(),
            IS_AUDIO_LOGGING_ENABLED,
            this,
            PREFERRED_AUDIO_DEVICE_LIST
        );
        savedVolumeControlStream = getVolumeControlStream();
        setVolumeControlStream(AudioManager.STREAM_VOICE_CALL);

        Intent intent = getIntent();

        this.accessToken = intent.getStringExtra("token");
        this.roomId = intent.getStringExtra("roomId");
        this.config = (CallConfig) intent.getSerializableExtra("config");

        Log.d(TwilioVideo.TAG, "BEFORE REQUEST PERMISSIONS");
        if (!hasPermissionForCameraAndMicrophone()) {
            Log.d(TwilioVideo.TAG, "REQUEST PERMISSIONS");
            requestPermissions();
        } else {
            Log.d(TwilioVideo.TAG, "PERMISSIONS OK. CREATE LOCAL MEDIA");
            createAudioAndVideoTracks();
            connectToRoom();
        }

        /*
         * Set the initial state of the UI
         */
        initializeUI();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        if (requestCode == PERMISSIONS_REQUEST_CODE) {
            boolean permissionsGranted = true;

            for (int grantResult : grantResults) {
                permissionsGranted &= grantResult == PackageManager.PERMISSION_GRANTED;
            }

            if (permissionsGranted) {
                createAudioAndVideoTracks();
                connectToRoom();
            } else {
                publishEvent(CallEvent.of(PERMISSIONS_REQUIRED));
                handleConnectionError();
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        /*
         * If the local video track was released when the app was put in the background, recreate.
         */
        if (localVideoTrack == null && hasPermissionForCameraAndMicrophone()) {
            localVideoTrack = LocalVideoTrack.create(this,
                true,
                cameraCapturer,
                LOCAL_VIDEO_TRACK_NAME);
            localVideoTrack.addSink(thumbnailVideoView);

            /*
             * If connected to a Room then share the local video track.
             */
            if (localParticipant != null) {
                localParticipant.publishTrack(localVideoTrack);
            }
        }
    }

    @Override
    protected void onPause() {
        /*
         * Release the local video track before going in the background. This ensures that the
         * camera can be used by other applications while this app is in the background.
         */
        if (localVideoTrack != null) {
            /*
             * If this local video track is being shared in a Room, unpublish from room before
             * releasing the video track. Participants will be notified that the track has been
             * unpublished.
             */
            if (localParticipant != null) {
                localParticipant.unpublishTrack(localVideoTrack);
            }

            localVideoTrack.release();
            localVideoTrack = null;
        }
        super.onPause();
    }

    @Override
    public void onBackPressed() {
        if (config.isDisableBackButton()) {
            return;
        }
        super.onBackPressed();
        overridePendingTransition(0, 0);
    }

    @Override
    protected void onDestroy() {

        /*
         * Tear down audio management and restore previous volume stream
         */
        audioSwitch.stop();
        setVolumeControlStream(savedVolumeControlStream);

        /*
         * Always disconnect from the room before leaving the Activity to
         * ensure any memory allocated to the Room resource is freed.
         */
        if (room != null && room.getState() != Room.State.DISCONNECTED) {
            room.disconnect();
            disconnectedFromOnDestroy = true;
            room = null;
        }

        /*
         * Release the local audio and video tracks ensuring any memory allocated to audio
         * or video is freed.
         */
        if (localAudioTrack != null) {
            localAudioTrack.release();
            localAudioTrack = null;
        }
        if (localVideoTrack != null) {
            localVideoTrack.release();
            localVideoTrack = null;
        }

        publishEvent(CallEvent.of(CLOSED));

        TwilioVideoManager.getInstance().setActionListenerObserver(null);

        super.onDestroy();
    }

    private void startAudio() {
        audioSwitch.start(new Function2<List<? extends AudioDevice>, AudioDevice, Unit>() {
            @Override
            public Unit invoke(List<? extends AudioDevice> audioDevices, AudioDevice audioDevice) {
                return Unit.INSTANCE;
            }
        });
        audioSwitch.activate();
    }

    private boolean hasPermissionForCameraAndMicrophone() {
        int resultCamera = ContextCompat.checkSelfPermission(this,
            Manifest.permission.CAMERA);
        int resultMic = ContextCompat.checkSelfPermission(this,
            Manifest.permission.RECORD_AUDIO);
        return resultCamera == PackageManager.PERMISSION_GRANTED &&
            resultMic == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermissions() {
        ActivityCompat.requestPermissions(
            this,
            TwilioVideo.PERMISSIONS_REQUIRED,
            PERMISSIONS_REQUEST_CODE);
    }

    private void createAudioAndVideoTracks() {
        // Share your microphone
        localAudioTrack = LocalAudioTrack.create(this, true,
            LOCAL_AUDIO_TRACK_NAME);

        // Share your camera
        cameraCapturer = new CameraCapturerCompat(this,
            CameraCapturerCompat.Source.FRONT_CAMERA);
        localVideoTrack = LocalVideoTrack.create(this,
            true,
            cameraCapturer,
            LOCAL_VIDEO_TRACK_NAME);
        this.moveLocalVideoToThumbnailView();
    }

    private void connectToRoom() {
        startAudio();
        ConnectOptions.Builder connectOptionsBuilder = new ConnectOptions.Builder(accessToken)
            .roomName(this.roomId)
            .enableIceGatheringOnAnyAddressPorts(true);

        /*
         * Add local audio track to connect options to share with participants.
         */
        if (localAudioTrack != null) {
            connectOptionsBuilder
                .audioTracks(Collections.singletonList(localAudioTrack));
        }

        /*
         * Add local video track to connect options to share with participants.
         */
        if (localVideoTrack != null) {
            connectOptionsBuilder.videoTracks(Collections.singletonList(localVideoTrack));
        }

        room = Video.connect(this, connectOptionsBuilder.build(), roomListener());
    }

    /*
     * The initial state when there is no active conversation.
     */
    private void initializeUI() {
        setDisconnectAction();

        if (config.getPrimaryColorHex() != null) {
            int primaryColor = Color.parseColor(config.getPrimaryColorHex());
            ColorStateList color = ColorStateList.valueOf(primaryColor);
            connectActionFab.setBackgroundTintList(color);
        }

        if (config.getSecondaryColorHex() != null) {
            int secondaryColor = Color.parseColor(config.getSecondaryColorHex());
            ColorStateList color = ColorStateList.valueOf(secondaryColor);
            switchCameraActionFab.setBackgroundTintList(color);
            localVideoActionFab.setBackgroundTintList(color);
            muteActionFab.setBackgroundTintList(color);
            switchAudioActionFab.setBackgroundTintList(color);
        }

        switchCameraActionFab.show();
        switchCameraActionFab.setOnClickListener(switchCameraClickListener());
        localVideoActionFab.show();
        localVideoActionFab.setOnClickListener(localVideoClickListener());
        muteActionFab.show();
        muteActionFab.setOnClickListener(muteClickListener());
        switchAudioActionFab.show();
        switchAudioActionFab.setOnClickListener(switchAudioClickListener());
    }

    private void showAudioDevices() {
        List<AudioDevice> availableAudioDevices = audioSwitch.getAvailableAudioDevices();

        if (availableAudioDevices.isEmpty()) {
            return;
        }

        AudioDevice selectedDevice = audioSwitch.getSelectedAudioDevice();
        int selectedDeviceIndex = availableAudioDevices.indexOf(selectedDevice);

        List<String> audioDeviceNames = TwilioVideoUtils.getAudioDeviceNames(
            this, availableAudioDevices
        );

        new AlertDialog.Builder(this)
            .setSingleChoiceItems(
                audioDeviceNames.toArray(new CharSequence[0]),
                selectedDeviceIndex,
                (dialog, index) -> {
                    dialog.dismiss();
                    AudioDevice selectedAudioDevice = availableAudioDevices.get(index);
                    audioSwitch.selectDevice(selectedAudioDevice);
                    audioSwitch.activate();
                })
            .create()
            .show();
    }

    /*
     * The actions performed during disconnect.
     */
    private void setDisconnectAction() {
        connectActionFab.setImageDrawable(ContextCompat.getDrawable(this,
            FAKE_R.getDrawable("ic_call_end_white_24px")));
        connectActionFab.show();
        connectActionFab.setOnClickListener(disconnectClickListener());
    }

    /*
     * Called when participant joins the room
     */
    private void addRemoteParticipant(RemoteParticipant participant) {
        remoteParticipantIdentity = participant.getIdentity();


        /*
         * Add participant renderer
         */
        if (participant.getRemoteVideoTracks().size() > 0) {
            RemoteVideoTrackPublication remoteVideoTrackPublication =
                participant.getRemoteVideoTracks().get(0);

            /*
             * Only render video tracks that are subscribed to
             */
            if (remoteVideoTrackPublication.isTrackSubscribed()) {
                addRemoteParticipantVideo(remoteVideoTrackPublication.getRemoteVideoTrack());
            }
        }

        /*
         * Start listening for participant media events
         */
        participant.setListener(remoteParticipantListener());
    }

    /*
     * Set primary view as renderer for participant video track
     */
    private void addRemoteParticipantVideo(VideoTrack videoTrack) {
        primaryVideoView.setVisibility(View.VISIBLE);
        primaryVideoView.setMirror(false);
        videoTrack.addSink(primaryVideoView);
    }

    private void moveLocalVideoToThumbnailView() {
        if (thumbnailVideoView.getVisibility() == View.GONE) {
            thumbnailVideoView.setVisibility(View.VISIBLE);
            if (localVideoTrack != null) {
                localVideoTrack.removeSink(primaryVideoView);
                localVideoTrack.addSink(thumbnailVideoView);
            }
            thumbnailVideoView.setMirror(cameraCapturer.getCameraSource() ==
                CameraCapturerCompat.Source.FRONT_CAMERA);
        }
    }

    /*
     * Called when participant leaves the room
     */
    private void removeRemoteParticipant(RemoteParticipant remoteParticipant) {
        if (!remoteParticipant.getIdentity().equals(remoteParticipantIdentity)) {
            return;
        }

        /*
         * Remove participant renderer
         */
        if (!remoteParticipant.getRemoteVideoTracks().isEmpty()) {
            RemoteVideoTrackPublication remoteVideoTrackPublication =
                remoteParticipant.getRemoteVideoTracks().get(0);

            /*
             * Remove video only if subscribed to participant track
             */
            if (remoteVideoTrackPublication.isTrackSubscribed()) {
                removeParticipantVideo(remoteVideoTrackPublication.getRemoteVideoTrack());
            }
        }
    }

    private void removeParticipantVideo(VideoTrack videoTrack) {
        primaryVideoView.setVisibility(View.GONE);
        videoTrack.removeSink(primaryVideoView);
    }

    /*
     * Room events listener
     */
    private Room.Listener roomListener() {
        return new Room.Listener() {
            @Override
            public void onConnected(Room room) {
                localParticipant = room.getLocalParticipant();
                publishEvent(CallEvent.of(CONNECTED).withRoomCtx(room));

                final List<RemoteParticipant> remoteParticipants = room.getRemoteParticipants();
                if (remoteParticipants != null && !remoteParticipants.isEmpty()) {
                    addRemoteParticipant(remoteParticipants.get(0));
                }
            }

            @Override
            public void onConnectFailure(Room room, TwilioException e) {
                publishEvent(CallEvent.ofError(CONNECT_FAILURE, e).withRoomCtx(room));
                TwilioVideoActivity.this.handleConnectionError();
            }

            @Override
            public void onReconnecting(@NonNull Room room, @NonNull TwilioException e) {
                publishEvent(CallEvent.ofError(RECONNECTING, e).withRoomCtx(room));
            }

            @Override
            public void onReconnected(@NonNull Room room) {
                publishEvent(CallEvent.of(RECONNECTED).withRoomCtx(room));
            }

            @Override
            public void onDisconnected(Room room, TwilioException e) {
                localParticipant = null;
                TwilioVideoActivity.this.room = null;
                // Only reinitialize the UI if disconnect was not called from onDestroy()
                if (!disconnectedFromOnDestroy && e != null) {
                    publishEvent(CallEvent.ofError(DISCONNECTED_WITH_ERROR, e).withRoomCtx(room));
                    handleConnectionError();
                } else {
                    publishEvent(CallEvent.of(DISCONNECTED).withRoomCtx(room));
                }
            }

            @Override
            public void onParticipantConnected(Room room, RemoteParticipant participant) {
                publishEvent(CallEvent.of(PARTICIPANT_CONNECTED).withRoomCtx(room));
                addRemoteParticipant(participant);
            }

            @Override
            public void onParticipantDisconnected(Room room, RemoteParticipant participant) {
                publishEvent(CallEvent.of(PARTICIPANT_DISCONNECTED).withRoomCtx(room));
                removeRemoteParticipant(participant);
            }

            @Override
            public void onRecordingStarted(Room room) {
                /*
                 * Indicates when media shared to a Room is being recorded. Note that
                 * recording is only available in our Group Rooms developer preview.
                 */
                Log.d(TwilioVideo.TAG, "onRecordingStarted");
            }

            @Override
            public void onRecordingStopped(Room room) {
                /*
                 * Indicates when media shared to a Room is no longer being recorded. Note that
                 * recording is only available in our Group Rooms developer preview.
                 */
                Log.d(TwilioVideo.TAG, "onRecordingStopped");
            }
        };
    }

    private RemoteParticipant.Listener remoteParticipantListener() {
        return new RemoteParticipant.Listener() {

            @Override
            public void onAudioTrackPublished(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onAudioTrackPublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteAudioTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteAudioTrackPublication.getTrackSid(),
                    remoteAudioTrackPublication.isTrackEnabled(),
                    remoteAudioTrackPublication.isTrackSubscribed(),
                    remoteAudioTrackPublication.getTrackName()));
            }

            @Override
            public void onAudioTrackUnpublished(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onAudioTrackUnpublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteAudioTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteAudioTrackPublication.getTrackSid(),
                    remoteAudioTrackPublication.isTrackEnabled(),
                    remoteAudioTrackPublication.isTrackSubscribed(),
                    remoteAudioTrackPublication.getTrackName()));
            }

            @Override
            public void onAudioTrackSubscribed(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication,
                RemoteAudioTrack remoteAudioTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onAudioTrackSubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteAudioTrack: enabled=%b, playbackEnabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteAudioTrack.isEnabled(),
                    remoteAudioTrack.isPlaybackEnabled(),
                    remoteAudioTrack.getName()));
            }

            @Override
            public void onAudioTrackSubscriptionFailed(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication,
                TwilioException twilioException
            ) {
                Log.i(TwilioVideo.TAG, String.format("onAudioTrackSubscriptionFailed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteAudioTrackPublication: sid=%b, name=%s]" +
                        "[TwilioException: code=%d, message=%s]",
                    remoteParticipant.getIdentity(),
                    remoteAudioTrackPublication.getTrackSid(),
                    remoteAudioTrackPublication.getTrackName(),
                    twilioException.getCode(),
                    twilioException.getMessage()));
            }

            @Override
            public void onAudioTrackUnsubscribed(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication,
                RemoteAudioTrack remoteAudioTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onAudioTrackUnsubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteAudioTrack: enabled=%b, playbackEnabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteAudioTrack.isEnabled(),
                    remoteAudioTrack.isPlaybackEnabled(),
                    remoteAudioTrack.getName()));
            }

            @Override
            public void onVideoTrackPublished(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onVideoTrackPublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteVideoTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteVideoTrackPublication.getTrackSid(),
                    remoteVideoTrackPublication.isTrackEnabled(),
                    remoteVideoTrackPublication.isTrackSubscribed(),
                    remoteVideoTrackPublication.getTrackName()));
            }

            @Override
            public void onVideoTrackUnpublished(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onVideoTrackUnpublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteVideoTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteVideoTrackPublication.getTrackSid(),
                    remoteVideoTrackPublication.isTrackEnabled(),
                    remoteVideoTrackPublication.isTrackSubscribed(),
                    remoteVideoTrackPublication.getTrackName()));
            }

            @Override
            public void onVideoTrackSubscribed(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication,
                RemoteVideoTrack remoteVideoTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onVideoTrackSubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteVideoTrack: enabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteVideoTrack.isEnabled(),
                    remoteVideoTrack.getName()));
                publishEvent(CallEvent.of(REMOTE_VIDEO_TRACK_ADDED).withRoomCtx(room));
                addRemoteParticipantVideo(remoteVideoTrack);
            }

            @Override
            public void onVideoTrackSubscriptionFailed(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication,
                TwilioException twilioException
            ) {
                Log.i(TwilioVideo.TAG, String.format("onVideoTrackSubscriptionFailed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteVideoTrackPublication: sid=%b, name=%s]" +
                        "[TwilioException: code=%d, message=%s]",
                    remoteParticipant.getIdentity(),
                    remoteVideoTrackPublication.getTrackSid(),
                    remoteVideoTrackPublication.getTrackName(),
                    twilioException.getCode(),
                    twilioException.getMessage()));
            }

            @Override
            public void onVideoTrackUnsubscribed(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication,
                RemoteVideoTrack remoteVideoTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onVideoTrackUnsubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteVideoTrack: enabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteVideoTrack.isEnabled(),
                    remoteVideoTrack.getName()));
                publishEvent(CallEvent.of(REMOTE_VIDEO_TRACK_REMOVED).withRoomCtx(room));
                removeParticipantVideo(remoteVideoTrack);
            }

            @Override
            public void onDataTrackPublished(
                RemoteParticipant remoteParticipant,
                RemoteDataTrackPublication remoteDataTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onDataTrackPublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteDataTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteDataTrackPublication.getTrackSid(),
                    remoteDataTrackPublication.isTrackEnabled(),
                    remoteDataTrackPublication.isTrackSubscribed(),
                    remoteDataTrackPublication.getTrackName()));
            }

            @Override
            public void onDataTrackUnpublished(
                RemoteParticipant remoteParticipant,
                RemoteDataTrackPublication remoteDataTrackPublication
            ) {
                Log.i(TwilioVideo.TAG, String.format("onDataTrackUnpublished: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteDataTrackPublication: sid=%s, enabled=%b, " +
                        "subscribed=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteDataTrackPublication.getTrackSid(),
                    remoteDataTrackPublication.isTrackEnabled(),
                    remoteDataTrackPublication.isTrackSubscribed(),
                    remoteDataTrackPublication.getTrackName()));
            }

            @Override
            public void onDataTrackSubscribed(
                RemoteParticipant remoteParticipant,
                RemoteDataTrackPublication remoteDataTrackPublication,
                RemoteDataTrack remoteDataTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onDataTrackSubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteDataTrack: enabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteDataTrack.isEnabled(),
                    remoteDataTrack.getName()));
            }

            @Override
            public void onDataTrackSubscriptionFailed(
                RemoteParticipant remoteParticipant,
                RemoteDataTrackPublication remoteDataTrackPublication,
                TwilioException twilioException
            ) {
                Log.i(TwilioVideo.TAG, String.format("onDataTrackSubscriptionFailed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteDataTrackPublication: sid=%b, name=%s]" +
                        "[TwilioException: code=%d, message=%s]",
                    remoteParticipant.getIdentity(),
                    remoteDataTrackPublication.getTrackSid(),
                    remoteDataTrackPublication.getTrackName(),
                    twilioException.getCode(),
                    twilioException.getMessage()));
            }

            @Override
            public void onDataTrackUnsubscribed(
                RemoteParticipant remoteParticipant,
                RemoteDataTrackPublication remoteDataTrackPublication,
                RemoteDataTrack remoteDataTrack
            ) {
                Log.i(TwilioVideo.TAG, String.format("onDataTrackUnsubscribed: " +
                        "[RemoteParticipant: identity=%s], " +
                        "[RemoteDataTrack: enabled=%b, name=%s]",
                    remoteParticipant.getIdentity(),
                    remoteDataTrack.isEnabled(),
                    remoteDataTrack.getName()));
            }

            @Override
            public void onAudioTrackEnabled(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication) {
            }

            @Override
            public void onAudioTrackDisabled(
                RemoteParticipant remoteParticipant,
                RemoteAudioTrackPublication remoteAudioTrackPublication) {
            }

            @Override
            public void onVideoTrackEnabled(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication) {
            }

            @Override
            public void onVideoTrackDisabled(
                RemoteParticipant remoteParticipant,
                RemoteVideoTrackPublication remoteVideoTrackPublication) {
            }
        };
    }

    private View.OnClickListener disconnectClickListener() {
        return new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (config.isHangUpInApp()) {
                    // Send the event to the web side in order to allow developers to do something else before disconnecting the room
                    publishEvent(CallEvent.of(HANG_UP).withRoomCtx(room));
                } else {
                    onDisconnect();
                }
            }
        };
    }

    private View.OnClickListener switchCameraClickListener() {
        return new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (cameraCapturer != null) {
                    CameraCapturerCompat.Source cameraSource = cameraCapturer.getCameraSource();
                    cameraCapturer.switchCamera();
                    thumbnailVideoView.setMirror(
                        cameraSource == CameraCapturerCompat.Source.BACK_CAMERA);
                }
            }
        };
    }

    private View.OnClickListener switchAudioClickListener() {
        return new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showAudioDevices();
            }
        };
    }

    private View.OnClickListener localVideoClickListener() {
        return new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                /*
                 * Enable/disable the local video track
                 */
                if (localVideoTrack != null) {
                    boolean enable = !localVideoTrack.isEnabled();
                    localVideoTrack.enable(enable);
                    int icon;
                    if (enable) {
                        icon = FAKE_R.getDrawable("ic_videocam_green_24px");
                        switchCameraActionFab.show();
                    } else {
                        icon = FAKE_R.getDrawable("ic_videocam_off_red_24px");
                        switchCameraActionFab.hide();
                    }

                    localVideoActionFab.setImageDrawable(
                        ContextCompat.getDrawable(TwilioVideoActivity.this, icon));
                }
            }
        };
    }

    private View.OnClickListener muteClickListener() {
        return new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                /*
                 * Enable/disable the local audio track. The results of this operation are
                 * signaled to other Participants in the same Room. When an audio track is
                 * disabled, the audio is muted.
                 */
                if (localAudioTrack != null) {
                    boolean enable = !localAudioTrack.isEnabled();
                    localAudioTrack.enable(enable);
                    int icon = enable ?
                        FAKE_R.getDrawable("ic_mic_green_24px")
                        : FAKE_R.getDrawable("ic_mic_off_red_24px");
                    muteActionFab.setImageDrawable(ContextCompat.getDrawable(
                        TwilioVideoActivity.this, icon));
                }
            }
        };
    }

    private void handleConnectionError() {
        Log.i(TwilioVideo.TAG, "Connection error happened. Finishing videocall...");
        this.finish();
    }

    @Override
    public void onDisconnect() {
        /*
         * Disconnect from room
         */
        if (room != null) {
            room.disconnect();
        }

        finish();
    }

    @Override
    public void finish() {
        audioSwitch.deactivate();
        super.finish();
        overridePendingTransition(0, 0);
    }

    private void publishEvent(CallEvent event) {
        TwilioVideoManager.getInstance().publishEvent(event);
    }

    @Override
    public void onAudioFocusChange(int i) {
        Log.i(TwilioVideo.TAG, "Audio focus changed");
    }
}
