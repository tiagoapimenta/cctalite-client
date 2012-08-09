cctalite-client
===============

Command and Conquer Tiberium Alliances Client Lite with Bot

Zlib License
------------

Copyright (c) 201> tiagoapimenta (at) gmail (dot) com

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.

Install
-------

You'll need Ruby, I used 1.9.2 from RVM, but it should work with 1.8.3 too.

I didn't have problems with JSON with RVM, but if you do so, you'll need this
gem.

The bot needs *users.rb* file with your account user and password, there is a
sample file *users.rb.example*, you can copy it and change its content.

This bot collect resources from all cities, repair damaged units and buildings,
and upgrade them, I did a algorithm to search for the weakest units and
buildings to upgrade first, if you don't like so, feel free to change it.

Information
-----------

Pardon me because I don't know the original name of them:

*Buildings*:

* 1. Construction;
* 2. Refinary;
* 5. Silo;
* 10. Power Plant;
* 16. Acumulator;
* 24. Command Center;
* 32. Havester
* 34. Barrack;
* 35. Factory;
* 36. Airport;
* 40. Defense Headquarter;
* 42. Defense Institute;
* 81. Ion Cannon;
* 82. Skystrike Support;
* ?. Falcon Support?;

*Attack Units*:

* 81. Snipers Squad
* 86. Pitbull
* 87. Hunter
* 88. Guardian
* 92. Paladin
* 94. Firehawk

*Defense Units*:

* 98. Hunter
* 101. Guardian Cannon
* 102. MG Nest
* 106. Wall

*Products*:

* 120. Tiberium (30.000)
* 129. Cristals (30.000)
* 137. Energy (7.000)
* 138. Energy (15.000)
* 149. Credits (?)
* 154. Command Points (12)
