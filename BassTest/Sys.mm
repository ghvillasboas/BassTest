/*
 *  Sys.mm
 *  CondeNastTravelerGoldList
 *
 *  Created by Jan Kalis on 3/1/10.
 *  Copyright 2010 Glow Interactive. All rights reserved.
 *
 */

#import "Sys.h"
#import <sys/time.h>
#import <time.h>

namespace Sys
{
	namespace
	{
		double firstGetSeconds_ = -1.0;
		
		std::string resourcesDirectory_ = "";
		std::string documentsDirectory_ = "";

		std::string GetAbsoluteResourcesPath(std::string fileName)
		{
			return resourcesDirectory_ + "/" + fileName;
		}
		
		std::string GetAbsoluteDocumentsPath(std::string fileName)
		{
			return documentsDirectory_ + "/" + fileName;
		}
	}
	
	void Init()
	{
		srandom(time(NULL));

		// set resources directory
		char resourcesBuffer[5000];
		
		[[[NSBundle mainBundle] resourcePath] getCString:resourcesBuffer maxLength:1024 encoding:NSUTF8StringEncoding];
		resourcesDirectory_ = resourcesBuffer;
		
		// set documents directory
		char documentsBuffer[5000];
		
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		[[paths objectAtIndex:0] getCString:documentsBuffer maxLength:1024 encoding:NSUTF8StringEncoding];
		documentsDirectory_ = documentsBuffer;
	}


	std::string GetAbsolutePath(std::string fileName)
	{
		
		if (fileName[0] == '#')
		{
			std::string resourceFileName = fileName;
			
			// remove '#'
			resourceFileName.erase(0, 1);

			// get from resources
			return GetAbsoluteResourcesPath(resourceFileName);
			
		}
		else
		{
			// get from documents
			return GetAbsoluteDocumentsPath(fileName);
		}
		
		return "";
	}

	double GetSeconds()
	{
		struct timeval now;
		gettimeofday(&now, NULL);
		
		double time = now.tv_sec + now.tv_usec / 1000000.0;
		
		if (firstGetSeconds_ < 0.0) firstGetSeconds_ = time;
		
		return time - firstGetSeconds_;
	}
}
