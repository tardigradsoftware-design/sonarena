# NSS stub kütüphaneleri (Chromium için geçici çözüm)

`@sparticuz/chromium` sistemde `libnspr4/libnss3/libnssutil3` bekler; sandbox'ta
apt kapalı olduğu için bu kütüphaneler yok. Chromium binary'sinin ihtiyaç duyduğu
37 sembolü (+7 runtime sembolü) sahte olarak export eden bir .so üretiyoruz.

`PR_Now` gerçek `clock_gettime` ile implemente edildi — 0 dönerse Chromium'un tüm
zamanlayıcıları kilitlenir.

```bash
gcc -shared -fPIC -Wl,--version-script=ver.map -o libnss3.so stub2.c realimpl.c
cp libnss3.so libnssutil3.so; cp libnss3.so libnspr4.so
```

Kullanım: `LD_LIBRARY_PATH=<bu dizin> node render.mjs`
Sınır: HTTPS/ağ işlemleri stub kripto yüzünden çalışmaz; yerel HTML render'ı çalışır.
