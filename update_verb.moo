@verb $wiz:"@update-toaststunt-help" any any any
@program $wiz:@update-toaststunt-help
if (player != this)
  return E_PERM;
endif
"Check prerequisites:";
if (typeof(`function_info("curl") ! E_INVARG') == ERR)
  return player:tell("This verb relies on the curl builtin function to retrieve up-to-date documentation. Please ensure that the server has been compiled with the function enabled. You may need to install a supporting library, such as libcurl. Further information may be available here: https://github.com/lisdude/toaststunt/blob/master/docs/README.md#build-instructions");
endif
required_verbs = {{$object_utils, "has_property"}, {$player, "my_match_object"}, {$command_utils, "object_match_failed"}, {$string_utils, "nn"}, {$command_utils, "yes_or_no"}, {$recycler, "_create"}, {$string_utils, "english_list"}, {$list_utils, "map_builtin"}};
required_props = {{$sysobj, "generic_help"}, {$sysobj, "prog"}};
for x in (required_verbs)
  if (typeof(`verb_info(@x) ! E_VERBNF') == ERR)
    return player:tell("This verb relies on several LambdaCore verbs being present. It seems your database is missing: ", x[1], ":", x[2]);
  endif
endfor
for x in (required_props)
  if (typeof(`property_info(@x) ! E_PROPNF') == ERR)
    return player:tell("This verb relies on several LambdaCore properties being present. It seems your database is missing: ", x[1], ".", x[2]);
  endif
endfor
"Now do a special test for builtin_function help. Standard LambdaCore stores this in a property on $sysobj. ToastCore stores it in a map on $sysobj.";
if ($object_utils:has_property($sysobj, "builtin_function_help"))
  builtin_function_help = $builtin_function_help;
elseif ($object_utils:has_property($sysobj, "help_db") && maphaskey($help_db, "builtin_function"))
  builtin_function_help = $help_db["builtin_function"];
else
  "Not a fatal error, but we won't be able to check our priority";
  builtin_function_help = $failed_match;
endif
"Check if the update verb itself needs updated. (This does its own prerequisite checking because these functions aren't, strictly speaking, required for the main help update to succeed.)";
if (typeof(`verb_info($list_utils, "setremove_all") ! E_VERBNF') != ERR && typeof(`verb_info($object_utils, "has_verb") ! E_VERBNF') != ERR)
  verb_loc = $object_utils:has_verb(this, verb)[1];
  if (player.wizard || verb_info(verb_loc, verb)[1] == player)
    update_url = "https://raw.githubusercontent.com/lisdude/toaststunt-documentation/master/update_verb.moo";
    new_verb = $list_utils:setremove_all(decode_binary(call_function("curl", update_url)), 10)[3..$ - 1];
    if (new_verb != verb_code(verb_loc, verb) && $command_utils:yes_or_no(tostr("There is an update available for this verb. Would you like to apply it? You can review the updated code here: ", update_url)) == 1)
      set_verb_code(verb_loc, verb, new_verb);
      return player:tell("This verb has been updated. Please run it again.");
    endif
  endif
endif
"Try to identify an existing help database either by name or by input from the wizard.";
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
"If we failed, create a new database and add it to $prog help.";
if (db == 0)
  if ($command_utils:yes_or_no("No existing help database could be found. Would you like to create one?") == 1)
    db = $recycler:_create($generic_help);
    db:set_name("ToastStunt Help Database");
    if (player.wizard && $command_utils:yes_or_no("Would you like to add the new database to $prog.help?") == 1)
      $prog.help = setadd($prog.help, db);
    endif
  else
    return player:tell("Not creating a new database.");
  endif
endif
"Test if our help database has a higher priority than the LambdaCore builtin function help database. If not, offer to make it so.";
if (builtin_function_help != $failed_match && db in $prog.help > (builtin_function_help in $prog.help))
  if ($command_utils:yes_or_no("Would you like the ToastStunt help to take priority over LambdaCore help? This means that duplicate help files (such as move()) will prefer the ToastStunt version over the LambdaCore version.") == 1)
    $prog.help = setremove($prog.help, db);
    $prog.help = {db, @$prog.help};
  endif
endif
"Finally, actually update the help files.";
if ($command_utils:yes_or_no(tostr("Do you want to update the help database ", $string_utils:nn(db), "?")) != 1)
  return player:tell("Not updating.");
endif
if (!player.wizard && db.owner != player)
  return player:tell("You don't have permission to update ", $string_utils:nn(db), ".");
endif
url = "https://raw.githubusercontent.com/lisdude/toaststunt-documentation/master/function_help.moo";
data = call_function("curl", url);
if (typeof(data) == MAP)
  return player:tell("Error retrieving help text: ", data["message"]);
else
  regex = "^;;#123\\.\\(\"(?<property>.+)\"\\) = (?<value>.+)$";
  data = decode_binary(data);
  added = removed = updated = {};
  properties = [];
  for x in (data)
    yin();
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
      properties[property] = value;
    endif
  endfor
  "Check for properties that no longer exist in the remote.";
  for local_prop in (properties(db))
    yin();
    if (!maphaskey(properties, local_prop))
      if ($command_utils:yes_or_no(tostr("The property `", local_prop, "' no longer exists in the remote repository. Do you wish to delete the local version?")) == 1)
        removed = setadd(removed, local_prop);
        delete_property(db, local_prop);
      endif
    endif
  endfor
  for value, property in (properties)
    if ($object_utils:has_property(db, property))
      if (db.(property) != value)
        updated = setadd(updated, property);
        db.(property) = value;
      endif
    else
      add_property(db, property, value, {db.owner, "rc"});
      added = setadd(added, property);
    endif
  endfor
  player:tell("Done! ", added == {} && updated == {} && removed == {} ? "No changes found." | tostr("Added: ", $string_utils:english_list(added), ". Updated: ", $string_utils:english_list(updated), ".", removed == {} ? "" | tostr(" Removed: ", $string_utils:english_list(removed), ".")));
endif
.