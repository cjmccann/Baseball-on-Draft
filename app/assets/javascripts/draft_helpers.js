function changeDisplayedPlayersTable(select) {
    var options = {
        'Cumulative percentile difference': 'availablePlayersCumulative',
        'Absolute percentiles': 'availablePlayersAbsolute',
        'Absolute percentiles with positional adjustment': 'availablePlayersAbsolutePos',
        'Absolute percentiles, positional + remaining slot adjustment': 'availablePlayersAbsolutePosSlot'
    }

    if ($('#' + options[select.value]).length == 0) {
        toggleLoader();
        disableTableDropdown();
        $.ajax({
            type: 'GET',
            url: '/draft_helpers/' + getId() + '/' + options[select.value],
            success: function(data) {
                $('#availablePlayers').append(data);
                $('#' + options[select.value] + 'Table').on('scroll', scrollHeader);
            },
            error: function(xhr, status) {

            },
            complete: function (xhr, status) {
                setTableVisibility(options, select.value);
                filterByPositionValue($('select#position').find(':selected').text());
                toggleLoader();
                enableTableDropdown();
            }
        });
    } else {
        setTableVisibility(options, select.value);
    }
}

function disableTableDropdown() {
    $("select#playersTable").prop('disabled', true);
}

function enableTableDropdown() {
    $("select#playersTable").prop('disabled', false);
}

function getId() {
    return $('#availablePlayers').data('params-id');
}

function toggleLoader() {
    elem = $('.loader')
    if (elem.css("visibility") == "hidden") {
        elem.css("visibility", "visible");
    } else {
        elem.css("visibility", "hidden");
    }
}

function setTableVisibility(options, newVal) {
    for(key in options) {
        if (key == newVal) {
            // don't check for lenght, because we assume this is ALWAYS loaded
            $('#' + options[key]).show();
        } else {
            if ($('#' + options[key]).length) {
                $('#' + options[key]).hide();
            }
        }
    }
}

function filterByPosition(select) {
    filterByPositionValue(select.value);
}

function filterByPositionValue(value) {
    if(value == "All") {
        setAllPlayersVisible();
        return;
    } else {
        setAllPlayersHidden();
    }

    matchingPositions = getMatchingPositions(value);

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

function scrollHeader(e) {
    var table = e.currentTarget
    thead = table.getElementsByTagName('thead')[0];
        
    thead.scrollLeft = table.scrollLeft;
}

function scrollTeamHeader(e) {
    var table = e.currentTarget
    thead = table.getElementsByTagName('thead')[0];
        
    thead.scrollLeft = table.scrollLeft;
    document.getElementById('myTeamTotals').scrollLeft = table.scrollLeft;
}


function addPlayerClicked(e) {
    debugger;
    selector = "img[data-player-id='" + $(e).data('player-id') + "']"
    $(function() {

        $(selector).on('click', function(e){
            console.log('clicked', this);
        })   
    });
}

function addPlayer(e) {
    $.ajax({
        type: 'GET',
        url: '/draft_helpers/' + getId() + '/' + options[select.value],
        success: function(data) {
            $('#availablePlayers').append(data);
            $('#' + options[select.value] + 'Table').on('scroll', scrollHeader);
        },
        error: function(xhr, status) {

        },
        complete: function (xhr, status) {
            setTableVisibility(options, select.value);
            filterByPositionValue($('select#position').find(':selected').text());
            toggleLoader();
            enableTableDropdown();
        }
});

}

function removePlayer(e) {

    debugger;
}

window.onload = function() {
    document.getElementById('availablePlayersCumulativeTable').addEventListener('scroll', scrollHeader);
    // document.getElementById('availablePlayersAbsolutePosTable').addEventListener('scroll', scrollHeader);
    // document.getElementById('availablePlayersAbsolutePosSlotTable').addEventListener('scroll', scrollHeader);
    $('table#myTeam').on('scroll', scrollTeamHeader);

    $.contextMenu({
        selector: '.addPlayer', 
        trigger: 'left',
        callback: function(key, options) {
            var m = "clicked: " + key;
            window.console && console.log(m) || alert(m); 
        },
        items: {
            "edit": {name: "Edit", icon: "edit"},
            "cut": {name: "Cut", icon: "cut"},
            copy: {name: "Copy", icon: "copy"},
            "paste": {name: "Paste", icon: "paste"},
            "delete": {name: "Delete", icon: "delete"},
            "sep1": "---------",
            "quit": {name: "Quit", icon: function(){
                return 'context-menu-icon context-menu-icon-quit';
            }}
        }
    });
}
