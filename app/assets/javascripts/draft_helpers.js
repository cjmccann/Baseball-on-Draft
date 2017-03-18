function changeDisplayedPlayersTable(select) {
    var options = {
        'Cumulative percentile difference': '#availablePlayersCumulative',
        'Absolute percentiles': '#availablePlayersAbsolute',
        'Absolute percentiles with positional adjustment': '#availablePlayersAbsolutePos',
        'Absolute percentiles, positional + remaining slot adjustment': '#availablePlayersAbsolutePosSlot'
    }

    for(key in options) {
        if (key == select.value) {
            $(options[key]).show();
        } else {
            $(options[key]).hide();
        }
    }
}

function filterByPosition(select) {
    if(select.value == "All") {
        setAllPlayersVisible();
        return;
    } else {
        setAllPlayersHidden();
    }

    matchingPositions = getMatchingPositions(select.value);

    for(index in matchingPositions) {
        $('tr.' + matchingPositions[index] + getSelectedStatsType()).show();
    }
}

function getMatchingPositions(position) {
    positions = [ ]
    if (position != "MI" && position != "CI" && position != "OF" && position != "UTIL" && position != "P") {
        positions.push(position);
    } else {
        switch(position) {
            case "MI":
                positions.push("SS", "2B");
                break;
            case "CI":
                positions.push("1B", "3B");
                break;
            case "OF":
                positions.push("LF", "CF", "RF");
                break;
            case "UTIL":
                positions.push("C", "1B", "2B", "SS", "3B", "LF", "CF", "RF");
                break;
            case "P":
                positions.push("SP", "RP");
                break;
        }
    }

    return positions;
}

function setAllPlayersVisible() {
    $('tr.player' + getSelectedStatsType()).show();
}

function setAllPlayersHidden() {
    $('tr.player' + getSelectedStatsType()).hide()
}

function changeStatsType(input) {
    matching_positions = getSelectedPositionClasses();

    if (input.value == 'raw') {
        for (index in matching_positions) {
            $('tr.percentile' + matching_positions[index]).hide();
            $('tr.raw' + matching_positions[index]).show();
        }
    } else if (input.value == 'percentile') {
        for (index in matching_positions) {
            $('tr.raw' + matching_positions[index]).hide();
            $('tr.percentile' + matching_positions[index]).show();
        }
    }
}

function getSelectedStatsType() {
    var type = $('input[name="stats_type"]:checked').val();
    return "." + type
}

function getSelectedPositionClasses() {
    var pos = $('select#position').val();
    var position_classes = [ ]

    if (pos == "All") {
        position_classes = [ "" ]
    } else if (pos == "MI") {
        position_classes.push(".SS", ".2B");
    } else if (pos == "CI") {
        position_classes.push(".1B", ".3B");
    } else if (pos == "OF") {
        position_classes.push(".LF", ".CF", ".RF");
    } else if (pos == "UTIL") {
        position_classes.push(".C", ".1B", ".2B", ".SS", ".3B", ".LF", ".CF", ".RF");
    } else if (pos == "P") {
        position_classes.push(".SP", ".RP");
    } else {
        position_classes.push("." + pos);
    }

    return position_classes;
}

function scrollHeader(e){
    var table = e.currentTarget,
    thead = table.getElementsByTagName('thead')[0];
        
    thead.scrollLeft = table.scrollLeft;
}

window.onload = function() {
    document.getElementById('availablePlayersCumulativeTable').addEventListener('scroll', scrollHeader);
}

