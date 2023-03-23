/***
* Name: Experiment
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

/////////Contains the basic experiment of the simulation//////////
model All_Allowed
import "../experiments/General_Experiment.gaml"

global{
	init{
		mode<-"All allowed";
	}
}

experiment All_Allowed type:gui parent:General_Experiment{
	
}
/* Insert your model definition here */

