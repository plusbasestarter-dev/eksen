# EKSEN Supabase

Bu klasör yalnızca EKSEN için açılacak ayrı Supabase projesinde kullanılmalıdır. ParkBuddy veritabanına uygulanmamalıdır.

`migrations/001_initial.sql` öğrenci profili, ders/ünite/konu kataloğu, mastery/progress, learning events, Error DNA, spaced review, günlük plan, deneme ve AI recommendation tablolarını; ayrıca RLS politikalarını oluşturur.

Tarayıcı uygulamasında yalnız publishable key kullanılacaktır. `service_role` anahtarı istemciye konulmaz.
