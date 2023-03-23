/***
* Name: Activities
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Activities

import "../models/Propagation_simulation_model.gaml"

species activity parallel:true{
		string name;
		building target_building;
		int start_hour;
		int end_hour;
	}
	/*species activity_manager{
	//////////////////////////////////KID/////////////////////////////
	action get_kid_schedule{
		list<activity> kid_schedule;
		return kid_schedule;
	}
	list<activity> kid_weekend_schedule;

	/////////////////////////////////TEEN/////////////////////////////	
	list<activity> teen_schedule;
	list<activity> teen_weekend_schedule;
	/////////////////////////////////YOUNG////////////////////////////
	list<activity> young_schedule;
	list<activity> young_weekend_schedule;
	////////////////////////////////ADULT/////////////////////////////
	list<activity> adult_schedule;
	list<activity> adult_weekend_schedule;
	///////////////////////////////OLD///////////////////////////////
	list<activity> old_schedule;
	list<activity> old_weekend_schedule;
}*/
/* Insert your model definition here */

