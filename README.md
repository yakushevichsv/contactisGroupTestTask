# contactisGroupTestTask
Siri Usage, processing arithmetic formulas

This is a simple MVC (not MVVM, VIPER) single View app, which allows to compute algebraic text expressions. 

Speech is translated by Apple's speech framework. Original Core (TextAnalyzer) is optimized for word text.

Therefore there is a NativeSpeechAdapter for converting "optimized" text into raw words...

In case of some issues, debugPrint display messages into console, external exceptions are not thrown.

Trivial UI is copied from one of AppCoda's application, and a little bit refined....

There is some code duplication, and there are some TODOs... 

For core part(model) majority of unit tests are written. 
