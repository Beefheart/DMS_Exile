/*
	DMS_fnc_MissionStatusCheck

	Created by eraser1

	Each mission has its own index in "DMS_Mission_Arr".
	Every index is a subarray with the values:
	[
		_pos,
		_completionInfo,	//<--- More info in "DMS_AddMissionToMonitor"
		[_timeStarted,_timeUntilFail],
		[_AIUnit1,_AIUnit2,...,_AIUnitX],
		[
			[_cleanupObj1,_cleanupObj2,...,_cleanupObjX],
			[_vehicle1,_vehicle2,...,_vehicleX],
			[
				[_crate1,_crate_loot_values1],
				[_crate2,_crate_loot_values2]
			]
		],
		[_msgWIN,_msgLose],
		[_markerDot,_markerCircle],
		_side
	]
*/
if (DMS_Mission_Arr isEqualTo []) exitWith {};				// Empty array, no missions running

private ["_pos", "_success", "_timeStarted", "_timeUntilFail", "_units", "_buildings", "_vehs", "_crate_info_array", "_msgWIN", "_msgLose", "_markers", "_missionSide", "_arr", "_cleanupList"];


{
	try
	{
		if (DMS_DEBUG) then
		{
			diag_log format ["DMS_DEBUG MissionStatusCheck :: Checking Mission Status (index %1): %2",_forEachIndex,_x];
		};
		_pos						= _x select 0;
		_success					= (_x select 1) call DMS_fnc_MissionSuccessState;
		_timeStarted				= _x select 2 select 0;
		_timeUntilFail				= _x select 2 select 1;
		_units						= _x select 3;
		_buildings					= _x select 4 select 0;
		_vehs						= _x select 4 select 1;
		_crate_info_array			= _x select 4 select 2;
		_msgWIN						= _x select 5 select 0;
		_msgLose					= _x select 5 select 1;
		_markers 					= _x select 6;
		_missionSide				= _x select 7;

		if (_success) then
		{
			DMS_CleanUpList pushBack [_units+_buildings,diag_tickTime,DMS_CompletedMissionCleanupTime];

			if (_missionSide == "bandit") then
			{
				DMS_RunningBMissionCount = DMS_RunningBMissionCount - 1;
			}
			else
			{
				// Not yet implemented
			};

			_arr = DMS_Mission_Arr deleteAt _forEachIndex;

			{
				_x call DMS_fnc_FillCrate;
			} forEach _crate_info_array;

			_msgWIN call DMS_fnc_BroadcastMissionStatus;
			[_markers,"win"] call DMS_fnc_RemoveMarkers;

			throw format ["Mission Success at %1 with message %2.",_pos,_msgWIN];
		};

		if (DMS_MissionTimeoutReset && {[_pos,DMS_MissionTimeoutResetRange] call DMS_fnc_IsPlayerNearby}) then
		{
			_x set [2,[diag_tickTime,_timeUntilFail]];

			throw format ["Mission Timeout Extended at %1 with timeout after %2 seconds. Position: %3",diag_tickTime,_timeUntilFail,_pos];
		};

		if ((diag_tickTime-_timeStarted)>_timeUntilFail) then
		{
			//Nobody is nearby so just cleanup objects from here
			_cleanupList = (_units+_buildings+_vehs);

			{
				_cleanupList pushBack (_x select 0);
			} forEach _crate_info_array;

			_cleanupList call DMS_fnc_CleanUp;


			if (_missionSide == "bandit") then
			{
				DMS_RunningBMissionCount = DMS_RunningBMissionCount - 1;
			}
			else
			{
				// Not yet implemented
			};
			
			_arr = DMS_Mission_Arr deleteAt _forEachIndex;

			_msgLose call DMS_fnc_BroadcastMissionStatus;
			[_markers,"lose"] call DMS_fnc_RemoveMarkers;

			throw format ["Mission Fail at %1 with message %2.",_pos,_msgLose];
		};
	}
	catch
	{
		if (DMS_DEBUG) then
		{
			diag_log format ["DMS_DEBUG MissionStatusCheck :: %1",_exception];
		};
	};
} forEach DMS_Mission_Arr;