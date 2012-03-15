import deimos.portaudio;
import std.conv, std.stdio;

struct Phase
{
    float left=0, right=0;
}

extern(C) int sawtooth(const(void)* inputBuffer, void* outputBuffer,
                             size_t framesPerBuffer,
                             const(PaStreamCallbackTimeInfo)* timeInfo,
                             PaStreamCallbackFlags statusFlags,
                             void *userData)
{
    auto phase = cast(Phase*)userData;

    auto pout = cast(float*)outputBuffer;

    enum vol = 0.2f;

    foreach(i; 0 .. framesPerBuffer)
    {
        *pout++ = vol * phase.left;
        *pout++ = vol * phase.right;

        phase.left += 0.01f;
        if (phase.left >= 1.0f) phase.left -= 2.0f;

        phase.right += 0.03f;
        if (phase.right >= 1.0f) phase.right -= 2.0f;
    }
    return 0;
}

int main()
{
    enum SAMPLE_RATE = 44100;
    enum NUM_SECONDS = 5;

    PaStream* stream;
    PaError err;
    Phase phase_data;

    if ((err = Pa_Initialize()) != paNoError) goto Lerror;

    if ((err = Pa_OpenDefaultStream(&stream,
                                    0,
                                    2,
                                    paFloat32,
                                    SAMPLE_RATE,
                                    paFramesPerBufferUnspecified,
                                    &sawtooth,
                                    &phase_data))
        != paNoError) goto Lerror;

    if ((err = Pa_StartStream(stream)) != paNoError) goto Lerror;

    Pa_Sleep(NUM_SECONDS * 1000);

    if ((err = Pa_StopStream(stream)) != paNoError) goto Lerror;
    if ((err = Pa_CloseStream(stream)) != paNoError) goto Lerror;
    if ((err = Pa_Terminate()) != paNoError) goto Lerror;

    return 0;
 Lerror:
    stderr.writefln("error %s", to!string(Pa_GetErrorText(err)));
    return 1;
}
