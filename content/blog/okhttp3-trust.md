+++
title = "OkHttp 3.X on Android 4.4.4"
date = "2017-02-27T14:54:29-08:00"
tags = ["java", "code", "android"]
+++

This morning I was greeted at work by an unexpectedly-large number of crashes from a new Android release.  As it happens, OkHttp 3.X has issues on Android 4.4.4 and 4.4.2 - it cannot reliably load the system's default TrustManagers without looping and eventually crashing with an OutOfMemoryError.  The fix was simple - we can reliably load it ourselves, and provide it to new `OkHttpClient` instances.  For posterity, the solution we hit on follows below:

```java
TrustManagerFactory tmf;
try {
  String defaultAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
  tmf = TrustManagerFactory.getInstance(defaultAlgorithm);
} catch (NoSuchAlgorithmException e) {
  // The system *just* gave us this algo name :(
  throw new AssertionError(e); // no helping this one.
}

try {
  tmf.init((KeyStore) null); // null == system default keystore
} catch (KeyStoreException e) {
  throw new AssertionError(e); // again, no helping this one.
}

X509TrustManager trustManager = null;
for (TrustManager tm : tmf.getTrustManagers()) {
  if (tm instanceof X509TrustManager) {
    trustManager = (X509TrustManager) tm;
    break;
  }
}

if (trustManager == null) {
  throw new AssertionError("The system is not capable of handling X509 certificates - lol");
}

SSLSocketFactory ssf = (SSLSocketFactory) SSLSocketFactory.getDefault()

// Finally!  With the SSL socket factory and the X509 trust manager,
// we can safely build our HTTP client instance.
OkHttpClient client = new OkHttpClient.Builder()
    .sslSocketFactory(ssf, trustManager) 
    .build();
```

Of course, you won't want to do this more than once, but ideally you're already using a singleton client instance and are reaping the benefits of connection-pooling, a smaller memory footprint, etc.

Hopefully this helps someone - even me, a year from now.
