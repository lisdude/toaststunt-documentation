@verb $wiz:"@update-toaststunt-help" any any any
@program $wiz:@update-toaststunt-help
if (player != this)
  return E_PERM;
endif
if (!$object_utils:has_property($sysobj, "generic_help"))
  return player:tell("This database doesn't seem to have LambdaCore-style help databases.");
endif
db = 0;
if (!args)
  for x in (children($generic_help))
    if (x.name == "ToastStunt Help Database")
      db = x;
      break;
    endif
  endfor
else
  match = player:my_match_object(argstr);
  if ($command_utils:object_match_failed(match, argstr))
    return;
  elseif (isa(match, $generic_help))
    db = match;
  else
    return player:tell($string_utils:nn(match), " doesn't appear to be a help database.");
  endif
endif
if (db == 0)
  if ($command_utils:yes_or_no("No existing help database could be found. Would you like to create one?") == 1)
    db = $recycler:_create($generic_help);
    db:set_name("ToastStunt Help Database");
    if (player.wizard && ($command_utils:yes_or_no("Would you like to add the new database to $prog.help?") == 1))
      $prog.help = setadd($prog.help, db);
    endif
  else
    return player:tell("Not creating a new database.");
  endif
elseif ($command_utils:yes_or_no(tostr("Do you want to update the help database ", $string_utils:nn(db), "?")) != 1)
  return player:tell("Not updating.");
endif
if ((!player.wizard) && (db.owner != player))
  return player:tell("You don't have permission to update ", $string_utils:nn(db), ".");
endif
url = "https://raw.githubusercontent.com/lisdude/toaststunt-documentation/master/function_help.moo";
data = curl(url);
if (typeof(data) == MAP)
  return player:tell("Error retrieving help text: ", data["message"]);
else
  regex = "^;;#123\\.\\(\"(?<property>.+)\"\\) = (?<value>.+)$";
  data = decode_binary(data);
  added = updated = {};
  for x in (data)
    if (typeof(x) != STR)
      continue;
    endif
    if (match = pcre_match(x, regex))
      {property, value} = {match[1]["property"]["match"], $string_utils:to_value(match[1]["value"]["match"])};
      if (value[1] != 1)
        player:tell("Error parsing value for `", property, "'.");
        continue;
      else
        value = value[2];
      endif
      if ($object_utils:has_property(db, property))
        if (db.(property) != value)
          updated = setadd(updated, property);
          db.(property) = value;
        endif
      else
        add_property(db, property, value, {db.owner, "rc"});
        added = setadd(added, property);
      endif
    endif
  endfor
  player:tell("Done! ", ((added == {}) && (updated == {})) ? "No changes found." | tostr("Added: ", $string_utils:english_list(added), ". Updated: ", $string_utils:english_list(updated), "."));
endif
.
