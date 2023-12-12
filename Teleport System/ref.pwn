//D_TP_KEY D_TP_CATEGORY

#if !defined MAX_CATEGORY_TP_LEN
	#define MAX_CATEGORY_TP_LEN 				64
#endif
#if !defined INVALID_SEARCH_ID
	#define INVALID_SEARCH_ID					-1
#endif
#if !defined MAX_TELEPORT_TABLE_LEN
	#define MAX_TELEPORT_TABLE_LEN  			16
#endif
#if !defined MAX_TELEPORT_ITEMS_ON_PAGE
	#define MAX_TELEPORT_ITEMS_ON_PAGE			18
#endif
#if !defined MAX_TP_CATEGORIES
	#define MAX_TP_CATEGORIES					10
#endif
#if !defined MAX_TELEPORT_ITEM_NAME
	#define MAX_TELEPORT_ITEM_NAME				32
#endif
#if !defined MAX_TELEPORT_ITEM_KEYS
	#define MAX_TELEPORT_ITEM_KEYS				32
#endif

tp_OnDialogResponse(playerid, dialogid, response, listitem, const inputtext[])
{
	switch(dialogid)
	{
		case D_TP_CATEGORY:
		{
			if(!response) return true;

			new category_tp[MAX_CATEGORY_TP_LEN];

			sscanf(inputtext,"s[64]", category_tp);
			SetPVarString(playerid, "chosen_category_tp", category_tp);
			playerShowDialog(playerid, D_TP_KEY);

			return true;
		}
		case D_TP_KEY:
		{
			if(!response)
			{
				playerShowDialog(playerid, D_TP_CATEGORY);

				DeletePVar(playerid, "tp_page");
				DeletePVar(playerid, "chosen_category_tp");

				return false;
			}
            
            if(!strcmp(inputtext, "<< Пред. Страница", true))
			{
				SetPVarInt(playerid, "tp_page", GetPVarInt(playerid, "tp_page") - 1);
				playerShowDialog(playerid, D_TP_KEY);

				return true;
			}
			else if(!strcmp(inputtext, ">> След. Страница", true))
			{
				SetPVarInt(playerid, "tp_page", GetPVarInt(playerid, "tp_page") + 1);
				playerShowDialog(playerid, D_TP_KEY);

				return true;
			}

			new data[64];

			sscanf(inputtext, "s[64]", data);
			new sid = strfind(data, "[key:");

			if(sid != INVALID_SEARCH_ID)
			{
				strmid(data, data, sid + 5, strlen(data) - 2, sizeof(data));
			}

			callcmd::teleport(playerid, data);

			return true;
		}
	}
	return false;
}

CMD:teleport(playerid, params[])
{
    if(!CheckAdm(playerid, 1)) return true;

	new x_tp[32];
	if(sscanf(params, "s[64]", x_tp)) return playerShowDialog(playerid, D_TP_CATEGORY);

	static const fmt_query[] = "SELECT * FROM `"TABLE_TELEPORT"` WHERE `key` = '%s'";
	new query[sizeof fmt_query + (-2) + (-MAX_TELEPORT_TABLE_LEN) + sizeof(TABLE_TELEPORT) + sizeof(x_tp) + 1];

 	mysql_format(dbHandle, query, sizeof(query), fmt_query, x_tp);
	mysql_query(dbHandle, query);
	
	new rows = cache_num_rows();

	if(!rows)
	{
		playerShowDialog(playerid, D_TP_CATEGORY);
		return SendError(playerid, " Точка с таким ключём не найдена");
	}

	new Float: tp_position_x, Float: tp_position_y, Float: tp_position_y;
	new interior, virtualworld;

	cache_get_value_name_int(0, "interior", interior;
	cache_get_value_name_int(0, "virtualworld", virtualworld);
	cache_get_value_name_float(0, "tpx", tp_position_x);
	cache_get_value_name_float(0, "tpy", tp_position_y);
	cache_get_value_name_float(0, "tpz", tp_position_y);

	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
	    new vehicleid = GetPlayerVehicleID(playerid);
	    SetVehiclePos(vehicleid, tp_position_x, tp_position_y, tp_position_y);
	    LinkVehicleToInterior(vehicleid, interior);
		SetVehicleVirtualWorld(vehicleid, virtualworld);

	    SetPlayerInterior(playerid, interior;
	    SetPlayerVirtualWorld(playerid, virtualworld);

	}
	else
	{
		SetPlayerPos(playerid, tp_position_x, tp_position_y, tp_position_y);
	}

	SetPlayerInterior(playerid, interior);
	SetPlayerVirtualWorld(playerid, virtualworld);

	return SendClientMessage(playerid, COLOR_YELLOW, " Вы телепортированы");
}

alias:teleport("tp");
CMD:settp(playerid, params[])
{
	if (!IsFullDostup(pInfo[playerid][pName])) return SendClientMessage(playerid, COLOR_GREY, "Данная функция Вам недоступна");
	new action[32], first[32], third[32];

	if(sscanf(params, "s[32]", action)) return SendClientMessage(playerid, -1, " Введите: /settp [category|name|veh|add|dell]");
	if(!sscanf(params, "s[32]s[32]", action, first)) sscanf(params, "s[32]s[32]s[32]", action, first, third);
	
	static const fmt_query[] = "SELECT name FROM `"TABLE_TELEPORT"` WHERE `category` = '%s'";
	new query[sizeof fmt_query + (-MAX_TELEPORT_TABLE_LEN) + MAX_TELEPORT_ITEM_NAME + (-2) + 1];

	if(!strcmp(action, "category", true))
	{
	    new todo[32], category_name[MAX_TELEPORT_ITEM_NAME];
	    if(sscanf(params, "s[32]s[32]s[32]", action, todo, category_name)) return SendClientMessage(playerid, -1, " Введите: /settp category [add|delete] [name]");
	    
	    if(!strcmp(todo, "add", true))
	    {
	    	mysql_format(dbHandle, query, sizeof(query), fmt_query, category_name);

			new Cache: cache = mysql_query(dbHandle, query);
			new rows = cache_num_rows();
			
			if(rows)
			{
				return SendClientMessage(playerid, COLOR_GREY, " Категория уже существует!");
			}

			cache_delete(cache);
			SetPVarString(playerid, "new_category", category_name);
	        SendMes(playerid, -1, " Категория '%s' создана. Для появления в списке /tp нужно добавить один пункт 'name'", category_name);
	    }
	    else if(!strcmp(todo, "delete", true))
	    {
			mysql_format(dbHandle, query, sizeof(query), fmt_query, category_name);
			new Cache: cache = mysql_query(dbHandle, query);
			new rows = cache_num_rows();

			if(!rows)
			{
			    new strs[MAX_TELEPORT_ITEM_NAME];

				GetPVarString(playerid, "new_category", strs, MAX_CATEGORY_TP_LEN);
				if(!strlen(strs) || !rus_strcmp(strs, category_name))
				{
					return SendClientMessage(playerid, COLOR_GREY, " Нет такой категории");
				}
			}

			cache_delete(cache);

			query[0] = EOS;

			mysql_format(dbHandle, query, sizeof(query), "DELETE FROM `"TABLE_TELEPORT"` WHERE `category` = '%s'", category_name);
			new Cache: rows = mysql_query(dbHandle, query);

			if(rows)
			{
			    return SendMes(playerid, -1, " Категория '%s' удалена", category_name);
			}

			new string[MAX_TELEPORT_ITEM_NAME];
			GetPVarString(playerid, "new_category", string, MAX_CATEGORY_TP_LEN);

			if(!strlen(string))
			{
				return SendMes(playerid, COLOR_GREY, " Произошла ошибка удаления категории '%s'", category_name);
			}

			return DeletePVar(playerid, "new_category");
	    }
	    else return SendClientMessage(playerid, -1, " Введите: /settp category [add|delete] [name]");
	}
	else if(!strcmp(action, "name", true))
	{
	    new category_name[MAX_TELEPORT_ITEM_NAME];
	    if(sscanf(params, "s[32]s[32]", action, category_name)) return SendClientMessage(playerid, -1, " Введите: /settp name [name]");

		SetPVarString(playerid, "tp_name", category_name);
		
		return SendMes(playerid, -1, " Вы создали точку телепорта ''%s''. (( Исользуйте '/settp veh' для установки координат ))", category_name);
	}
	else if(!strcmp(action, "veh", true))
	{
	    new category_name[MAX_TELEPORT_ITEM_NAME];
		GetPVarString(playerid, "tp_name", category_name, MAX_TELEPORT_ITEM_NAME);

		if(!strlen(category_name)) return SendClientMessage(playerid, COLOR_GREY, " Вы не добавили точку телепорта. {FFFFFF}(( /settp name ))");
		if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, COLOR_GREY, " Вы не в автомобиле / Не на водительском месте!");
		
		new Float:tp_position_x, Float:tp_position_y, Float:tp_position_z;
		AntiCheatGetPos(playerid, tp_position_x, tp_position_y, tp_position_z);

		SetPVarFloat(playerid, "tpx", tp_position_x);
		SetPVarFloat(playerid, "tpy", tp_position_y);
		SetPVarFloat(playerid, "tpz", tp_position_z);

		SetPVarInt(playerid, "tpint", GetPlayerInterior(playerid));
		SetPVarInt(playerid, "tpvw", GetPlayerVirtualWorld(playerid));
		
		return SendClientMessage(playerid, -1, " Координаты сохранены. Введите '/settp add' для добавления точки");
	}
	else if(!strcmp(action, "add", true))
	{
	    new cat[32], action_keys[MAX_TELEPORT_ITEM_KEYS];
		if(sscanf(params, "s[32]s[32]s[32]", action, action_keys, cat)) return SendClientMessage(playerid, -1, " Введите: /settp add [key] [category]");

		for(new i; i < strlen(action_keys); i++)
		{
		    switch(action_keys[i])
		    {
		        case 'А'..'Я', 'а'..'я', ' ': return SendClientMessage(playerid, COLOR_GREY, " Ключ для телепорта не может состоять из русских букв или пробелов!");
		    }
		}

		new szQuery[512];
		static const fmt_query[] = "SELECT `category` FROM `"TABLE_TELEPORT"` WHERE `category` = '%s'";
		new query[sizeof fmt_query + (-2) + (-MAX_TELEPORT_TABLE_LEN) + sizeof(TABLE_TELEPORT) + sizeof(cat) + 1];

		mysql_format(dbHandle, query, sizeof(query), fmt_query, cat);
		mysql_query(dbHandle, query);

		if(!cache_num_rows())
		{
		    new strs[MAX_TELEPORT_ITEM_NAME];
			GetPVarString(playerid, "new_category", strs, MAX_TELEPORT_ITEM_NAME);

			if(!strlen(strs) || (strcmp(strs, cat, true) != 0 && rus_strcmp(strs, cat) != 0))
			{
				return SendClientMessage(playerid, COLOR_GREY, " Нет такой категории");
			}
		}

		new category_name[MAX_TELEPORT_ITEM_NAME];
		GetPVarString(playerid, "tp_name", category_name, MAX_TELEPORT_ITEM_NAME);

		if(!strlen(category_name))
		{
			return SendClientMessage(playerid, COLOR_GREY, " Вы не создали точку для телепорта");
		}
		
		new Float:tp_position_x = GetPVarFloat(playerid, "tpx"), Float:tp_position_y = GetPVarFloat(playerid, "tpy"), Float:tp_position_z = GetPVarFloat(playerid, "tpz");
		new interior = GetPVarInt(playerid, "tpint"), virtualworld = GetPVarInt(playerid, "tpvw");

		query[0] = EOS;
		
		mysql_format(dbHandle, query, sizeof query, "INSERT INTO `"TABLE_TELEPORT"` (`category`, `name`, `key`, `tp_position_x`, `tpy`, `tpz`, `interior`, `virtualworld`) \
		VALUES ('%s', '%s', '%s', '%f', '%f', '%f', '%d', '%d')", cat, category_name, action_keys, tp_position_x, tp_position_y, tp_position_z, interior, virtualworld);
		
		new Cache: query_result = mysql_query(dbHandle, query);

		if(query_result)
		{
			SendInfo(playerid, " Точка '%s' [key:%s] успешно добавлена", category_name, action_keys);
		}
		else
		{
		    cache_delete(query_result);
			mysql_format(dbHandle, szQuery, sizeof szQuery, "SELECT `key` FROM `"TABLE_TELEPORT"` WHERE `key` = '%s'", action_keys);
			mysql_query(dbHandle, szQuery);

			SendClientMessage(playerid, COLOR_GREY, " Произошла ошибка при добавлении точки");
			
			if(cache_num_rows()) return SendClientMessage(playerid, COLOR_GREY, " Такой ключ уже существует");
		}

		DeletePVar(playerid, "tpx");
		DeletePVar(playerid, "tpy");
		DeletePVar(playerid, "tpz");
		DeletePVar(playerid, "tpint");
		DeletePVar(playerid, "tpvw");
		DeletePVar(playerid, "tpname");

		return true;
	}
	else if(!strcmp(action, "dell", true))
	{
        new action_keys[MAX_TELEPORT_ITEM_KEYS];

		if(sscanf(params, "s[32]s[32]", action, action_keys)) return SendClientMessage(playerid, -1, " Введите: /settp dell [key]");
		
		static const fmt_query[] = "DELETE FROM `"TABLE_TELEPORT"` WHERE `key` = '%s'";
		new query[sizeof fmt_query + (-2) + (-MAX_TELEPORT_TABLE_LEN) + sizeof(TABLE_TELEPORT) + 1];

		mysql_format(dbHandle, query, sizeof(query), fmt_query, action_keys);
		new Cache:query_result = mysql_query(dbHandle, szQuery);

		if(query_result)
		{
			return SendInfo(playerid, " Точка [key:%s] успешно удалена", action_keys);
		}
		
		return SendClientMessage(playerid, COLOR_GREY, " Произошла ошибка при удалении точки");
	}

	return true;
}

stock rus_strcmp(const string[], const substring[], len = cellmax)
{
	if( len != cellmax )
	{
		for(new i; i < len && i < strlen(substring); i++)
	    {
			switch(string[i])
			{
			    case 'А'..'Я', 'а'..'я', ' ': {}
				default: continue;
			}
			switch(substring[i])
			{
			    case 'А'..'Я', 'а'..'я', ' ': {}
				default: continue;
			}
	        if(string[i] != substring[i])
	        return string[i] - substring[i];
	    }
	}
	else
	{
		new string_len = strlen(string);
		new substring_len = strlen(substring);

		for(new i; i < string_len && i < substring_len; i++)
	    {
			switch(string[i])
			{
			    case 'А'..'Я', 'а'..'я', ' ': {}
				default: continue;
			}
			switch(substring[i])
			{
			    case 'А'..'Я', 'а'..'я', ' ': {}
				default: continue;
			}

	        if(string[i] != substring[i])
	        {
	        	string[i] - substring[i];
	        }
	    }
	}
    return false;
}

stock playerShowDialog(playerid, dialogid)
{
	if(!IsPlayerConnected(playerid) || playerid == INVALID_PLAYER_ID)
	{
		return printf(" [WARNING] playerShowDialog >> Попытка показать диалог %d невалидному плеер хендлу %d", playerid, dialogid), 0;
	}

	switch(dialogid)
	{
		case D_TP_CATEGORY: // teleport
		{
			static const fmt_query[] = "SELECT `category` FROM `"TABLE_TELEPORT"`";
			new query[sizeof fmt_query + (-MAX_TELEPORT_TABLE_LEN) + sizeof(TABLE_TELEPORT) + 1];

			mysql_format(dbHandle, query, sizeof(query), fmt_query);
			mysql_query(dbHandle, query);

			new array[MAX_TP_CATEGORIES][MAX_TELEPORT_ITEM_NAME], category_tp[MAX_CATEGORY_TP_LEN];
			new rows = cache_num_rows();

			if(!rows) return SendClientMessage(playerid, COLOR_GREY, "Список пуст");

			for(new i; i < MAX_TP_CATEGORIES; i++)
			{
				format(array[i], sizeof(array[]), " ");
			}
			for(new i; i < rows; i++)
			{
				cache_get_value_name(i,"category",category_tp);
				if(!has_tp(array, category_tp))
				{
					for(new j; j < MAX_TP_CATEGORIES; j++)
					{
					    if(!strcmp(array[j], " ", true))
					    {
							format(array[j], sizeof(array), "%s", category_tp);
							break;
					    }
					}
				}
			}

			new index;
			for(new i; i < MAX_TP_CATEGORIES; i++)
			{
			    if(!strcmp(array[i], " ", true)) continue;

			    static const fmt_string[] = "[%i] %s\n";
				new string[fmt_string + (-6) + 2 + sizeof(array[]) + 1];

				format(string, sizeof(string), fmt_string, index, array[i]);
				strcat(t_string, string);

				index++;
			}

			return ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_LIST, "Телепорт", t_string, "Выбор", "Отмена");
		}
		case D_TP_KEY: // teleport
		{
			new category_tp[MAX_CATEGORY_TP_LEN];
			GetPVarString(playerid, "chosen_category_tp", category_tp, MAX_CATEGORY_TP_LEN);

			static const fmt_query[] = "SELECT `name`,`key` FROM `"TABLE_TELEPORT"` WHERE `category` = '%s'";
			new query[sizeof(fmt_query) + (-2) + (-MAX_TELEPORT_TABLE_LEN) + sizeof(TABLE_TELEPORT) + sizeof category_tp + 1];

		    mysql_format(dbHandle, query, sizeof(query), fmt_query, category_tp);
			mysql_query(dbHandle, query);

			new rows = cache_num_rows();
			if(!rows) return playerShowDialog(playerid, D_TP_CATEGORY);

			new index, start = MAX_TELEPORT_ITEMS_ON_PAGE * GetPVarInt(playerid, "tp_page");

			for(new i = start; i < rows && i < start + MAX_TELEPORT_ITEMS_ON_PAGE; i++)
			{
			    new teleport_name[MAX_TELEPORT_ITEM_NAME], action_keys[MAX_TELEPORT_ITEM_KEYS];

				cache_get_value_name(i, "name", teleport_name);
				cache_get_value_name(i, "key", action_keys);
			    
				static const fmt_string[] = "[%i] %s [key:%s] \n";
				new string[sizeof fmt_string + (-8) + start + sizeof(teleport_name) + sizeof(action_keys) + 1];

			    format(string, sizeof(string), fmt_string, i, teleport_name, action_keys);
			    strcat(t_string, string);

			    if(index >= MAX_TELEPORT_ITEMS_ON_PAGE - 1) break;

			    index++;
			}

			if(GetPVarInt(playerid, "tp_page") > 0)
		    {
		        strcat(t_string, "<< Пред. Страница\n");
		    }
		    if(index >= MAX_TELEPORT_ITEMS_ON_PAGE - 1 && rows > start + MAX_TELEPORT_ITEMS_ON_PAGE)
		    {
				strcat(t_string, ">> След. Страница");
			}

			return ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_LIST, "Меню", t_string, "Выбор", "Назад");	
		}
		default:
		{
			return printf(" [WARNING] playerShowDialog >> Попытка показать невалидный диалог %d плеер хендлу %d", dialogid, playerid);
		}

	}
	return false;
}
stock has_tp(const array[][], const text[])
{
	for(new i; i < MAX_TP_CATEGORIES; i++)
	{
		if(!strcmp(array[i], text, true))
		    return true;
	}
	return false;
}
