/*
 *  Sys.h
 *  CondeNastTravelerGoldList
 *
 *  Created by Jan Kalis on 3/1/10.
 *  Copyright 2010 Glow Interactive. All rights reserved.
 *
 */

#import <string>

namespace Sys
{
	extern void Init();
	extern std::string GetAbsolutePath(std::string fileName);
	extern double GetSeconds();
};
