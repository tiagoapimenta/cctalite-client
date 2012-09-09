cctalite-client
===============

Command and Conquer Tiberium Alliances Client Lite with Bot

Zlib License
------------

Copyright (c) 2012 tiagoapimenta (at) gmail (dot) com

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

I didn't have problems with JSON using RVM, but if you do so, you'll need this
gem.

The bot needs *users.rb* file with your account user and password, there is a
sample file *users.rb.example*, you can copy it and change its content.

This bot collect resources from all cities, repair damaged units and buildings,
and upgrade them, I did a algorithm to search for the weakest units and
buildings to upgrade first, if you don't like so, feel free to change it.
