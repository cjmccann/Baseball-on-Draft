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
        $('tr.' + matchingPositions[index]).show();
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
            case "CI":
                positions.push("1B", "3B");
            case "OF":
                positions.push("LF", "CF", "RF");
            case "UTIL":
                positions.push("C", "1B", "2B", "SS", "3B", "LF", "CF", "RF");
            case "P":
                positions.push("SP", "RP");

        }
    }

    return positions;
}

function setAllPlayersVisible() {
    $('tr.player').show();
}

function setAllPlayersHidden() {
    $('tr.player').hide()
}
