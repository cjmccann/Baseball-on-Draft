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


function getTeamItemList() {
    list = { }

    $('div.teamName').each(function(index) {
        elem = $(this);
        list[elem.attr('id')] = { name: elem.data('team-name'), icon: 'add' };
    });

    list['sep1'] = '---------';
    list['close'] = { name: 'Close', icon: 'quit' };

    return list;
}

function handleTeamListAction(key, options) {
    if (key != 'close') {
        addPlayerToTeam(key, this.closest('tr').data('player-id'))
    }
}

function addPlayerToTeam(teamId, playerId) {
    toggleLoader();

    $.ajax({
        type: 'POST',
        url: '/draft_helpers/' + getId() + '/addPlayerToTeam',
        data: {
            'teamId': teamId,
            'playerId': playerId
        },
        error: function(xhr, status) {
            console.log("ajax error in addPlayerToTeam");
            toggleLoader();
            debugger;
        },
    });
}

function removePlayerFromTeam(elem) {
    toggleLoader();
    playerId = $(elem).closest('tr').data('player-id');
    teamId = $(elem).closest('table').siblings('div.teamName').attr('id');

    $.ajax({
        type: 'POST',
        url: '/draft_helpers/' + getId() + '/removePlayerFromTeam',
        data: {
            'teamId': teamId,
            'playerId': playerId
        },
        error: function(xhr, status) {
            toggleLoader();
            console.log("ajax error in removePlayerFromTeam");
            debugger;
        },
    });
}

function showRemovePlayerButton() {
    $(this).children('td').children('img').show();
}

function hideRemovePlayerButton() {
    $(this).children('td').children('img').hide();
}

function initContextMenus() {
    $.contextMenu('destroy', '.addPlayer');

    $.contextMenu({
        selector: '.addPlayer', 
        className: 'data-title',
        trigger: 'left',
        events: {
            show: function(options) {
                $('.data-title').attr('data-menutitle', 'Add ' + this.parent().siblings('.playerName').text() + ' to:');
            }
        },
        callback: handleTeamListAction,
        items: getTeamItemList()
    });
}

ready = function() {
    document.getElementById('availablePlayersCumulativeTable').addEventListener('scroll', scrollHeader);
    $('table#myTeam').on('scroll', scrollTeamHeader);

    initContextMenus();

    $('body').addClass('stop-scrolling')

    $('tr.team').hover(showRemovePlayerButton, hideRemovePlayerButton);
}

document.addEventListener('turbolinks:load', ready);
