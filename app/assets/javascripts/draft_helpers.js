function changeDisplayedPlayersTable(select) {
    var options = {
        'Cumulative percentile difference': 'availablePlayersCumulative',
        'Absolute percentiles': 'availablePlayersAbsolute',
        'Distance from league averages': 'availablePlayersDiffFromAverage',
        'Absolute percentiles with positional adjustment': 'availablePlayersAbsolutePos',
        'Absolute percentiles, positional + remaining slot adjustment': 'availablePlayersAbsolutePosSlot',
        '': 'availablePlayersDummy'
    }

    if ($('#' + options[select.value]).length == 0) {
        showLoader();
        disableTableDropdown();
        $.ajax({
            type: 'GET',
            url: '/draft_helpers/' + getId() + '/availablePlayersTable',
            data: {
                tableId: options[select.value],
            },
            success: function(data) {
                $('#availablePlayers').append(data);
                $('#' + options[select.value] + 'Table').on('scroll', scrollHeader);
            },
            error: function(xhr, status) {

            },
            complete: function (xhr, status) {
                setTableVisibility(options, select.value);
                filterByPositionValue($('select#position').find(':selected').text());
                enableTableDropdown();
                searchAvailablePlayers($('#playerNameSearch')[0]);
                hideLoader();
            }
        });
    } else {
        setTableVisibility(options, select.value);
    }
}

function disableTableDropdown() {
    $("select#playersTable").prop('disabled', true);
}

function searchAvailablePlayers(input) {
    filter = input.value.toUpperCase();

    tbody = $('table.availablePlayers:visible').find('tbody');
    trIdPrefix = 'tr' + getSelectedStatsType();
    matching_positions = getSelectedPositionClasses();

    for (index in matching_positions) {
        trs = tbody.find(trIdPrefix + matching_positions[index])

        trs.each(function() {
            tr = $(this)
            td = tr.find('td.playerName');

            if(td.text().toUpperCase().indexOf(filter) > -1) {
                tr.show();
            } else {
                tr.hide();
            }
        });
    }
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

function showLoader() {
    $('.loader').css('visibility', 'visible');
}

function hideLoader() {
    $('.loader').css('visibility', 'hidden');
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

    searchAvailablePlayers($('#playerNameSearch')[0]);
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

    searchAvailablePlayers($('#playerNameSearch')[0]);
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

function setTeamHeaderScrolls() {
    $('table.team').each(function(index) {
        elem = $(this);

        elem.on('scroll', scrollTeamHeader);
    });
}

function scrollTeamHeader(e) {
    var table = e.currentTarget
    thead = table.getElementsByTagName('thead')[0];

    thead.scrollLeft = table.scrollLeft;
    $('table#' + table.id + '-totals').get(0).scrollLeft = table.scrollLeft;
}


function getTeamItemList(iconString) {
    list = { }

    $('div.teamName').each(function(index) {
        elem = $(this);
        list[elem.attr('id')] = { name: elem.data('team-name'), icon: iconString };
    });

    list['sep1'] = '---------';
    list['close'] = { name: 'Close', icon: 'quit' };

    return list;
}

function getOtherTeamList() {
    iconString = 'fa-chevron-right'
    list = { }

    $('div.teamName').each(function(index) {
        elem = $(this);

        if (elem.attr('id') != '1' && elem.attr('id') != 'allOtherTeamAvgs') {
            list[elem.attr('id')] = { name: elem.data('team-name'), icon: iconString };
        }
    });

    list['sep0'] = '---------';

    calcIconString = 'fa-calculator';
    list['allOtherTeamAvgs'] = { name: $('div.teamName#allOtherTeamAvgs').data('team-name'), icon: calcIconString }
    list['bestHitting'] = { name: 'Current best hitting team', icon: calcIconString }
    list['bestPitching'] = { name: 'Current best pitching team', icon: calcIconString }
    list['bestOverall'] = { name: 'Current best team overall', icon: calcIconString }

    list['sep1'] = '---------';
    list['close'] = { name: 'Close', icon: 'quit' };

    return list;
}

function handleTeamListAction(key, options) {
    if (key != 'close') {
        addPlayerToTeam(key, this.closest('tr').data('player-id'))
    }
}

function handleTeamSwitchAction(key, options) {
    if (key != 'close') {
        teamNameDiv = this.closest('div.teamName')
        oldTeamId = teamNameDiv.attr('id');

        if (key != 'bestHitting' && key != 'bestPitching' && key != 'bestOverall')
            newTeamId = key;
        else {
            otherTeamDiv = $('div#otherTeam');

            switch(key) {
                case "bestHitting":
                    newTeamId = otherTeamDiv.data('best-hitting')['id'];
                    break;
                case "bestPitching":
                    newTeamId = otherTeamDiv.data('best-pitching')['id'];
                    break;
                case "bestOverall":
                    newTeamId = otherTeamDiv.data('best-overall')['id'];
                    break;
            }
        }

        currentPlayerType = teamNameDiv.find('#playerType' + oldTeamId + ' option:selected').text();
        currentStatType = teamNameDiv.find('#statType' + oldTeamId + ' option:selected').text();

        $('div.teamName#' + oldTeamId).hide();
        $('table.team#bat' + oldTeamId).hide();
        $('table.team#pit' + oldTeamId).hide();
        $('table.teamTotals#bat' + oldTeamId + '-totals').hide();
        $('table.teamTotals#pit' + oldTeamId + '-totals').hide();

        new_teamNameDiv = $('div.teamName#' + newTeamId)
        new_teamNameDiv.show();

        $('table.team#bat' + newTeamId).show();
        $('table.team#pit' + newTeamId).show();
        $('table.teamTotals#bat' + newTeamId + '-totals').show();
        $('table.teamTotals#pit' + newTeamId + '-totals').show();

        playerType = new_teamNameDiv.find('#playerType' + newTeamId)
        playerType.val(currentPlayerType);
        playerType.change();

        statType = new_teamNameDiv.find('#statType' + newTeamId)
        statType.val(currentStatType);
        statType.change();
    }
}

function addPlayerToTeam(teamId, playerId) {
    showLoader();

    $.ajax({
        type: 'POST',
        url: '/draft_helpers/' + getId() + '/addPlayerToTeam',
        data: {
            'teamId': teamId,
            'playerId': playerId,
            'settings': { 
                'otherTeamSettings': getTeamSettingsForDivId('otherTeam'),
                'myTeamSettings': getTeamSettingsForDivId('myTeam'),
            }
        },
        error: function(xhr, status) {
            console.log("ajax error in addPlayerToTeam");
            hideLoader();
            debugger;
        },
    });
}

function getTeamSettingsForDivId(divId) {
    settings = { }
    div = $('#' + divId).find('div.teamName:visible')

    settings['id'] = div.attr('id');
    settings['playerType'] = div.find('select#playerType' + settings['id'] + ' :selected').text();
    settings['statType'] = div.find('select#statType' + settings['id'] + ' :selected').text();

    return settings;
}

function restorePreviousSettings() {
    previous_settings = $('div#draftHelperContainer').data('settings');

    if (!($.isEmptyObject(previous_settings))) {
        myTeamSetttings = previous_settings['myTeamSettings'];
        otherTeamSettings = previous_settings['otherTeamSettings'];

        $('select#playerType' + myTeamSetttings['id']).val(myTeamSetttings['playerType']);
        $('select#playerType' + myTeamSetttings['id']).change();

        $('select#statType' + myTeamSetttings['id']).val(myTeamSetttings['statType']);
        $('select#statType' + myTeamSetttings['id']).change();

        $('select#playerType' + otherTeamSettings['id']).val(otherTeamSettings['playerType']);
        $('select#playerType' + otherTeamSettings['id']).change();

        $('select#statType' + otherTeamSettings['id']).val(otherTeamSettings['statType']);
        $('select#statType' + otherTeamSettings['id']).change();
    }
}

function removePlayerFromTeam(elem) {
    showLoader();
    playerId = $(elem).closest('tr').data('player-id');
    teamId = $(elem).closest('table').data('team-id');

    $.ajax({
        type: 'POST',
        url: '/draft_helpers/' + getId() + '/removePlayerFromTeam',
        data: {
            'teamId': teamId,
            'playerId': playerId,
            'settings': { 
                'otherTeamSettings': getTeamSettingsForDivId('otherTeam'),
                'myTeamSettings': getTeamSettingsForDivId('myTeam'),
            }
        },
        error: function(xhr, status) {
            hideLoader();
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
    $.contextMenu('destroy', '.otherTeamHeader');

    $.contextMenu({
        selector: '.addPlayer', 
        className: 'data-player-title',
        trigger: 'left',
        events: {
            show: function(options) {
                $('.data-player-title').attr('data-menutitle', 'Add ' + this.parent().siblings('.playerName').text() + ' to:');
            }
        },
        callback: handleTeamListAction,
        items: getTeamItemList('add'),
    });

    $.contextMenu({
        selector: '.otherTeamHeader',
        className: 'data-team-name',
        trigger: 'left',
        events: {
            show: function(options) {
                $('.data-team-name').attr('data-menutitle', 'Switch to team: ');
            }
        },
        callback: handleTeamSwitchAction,
        items: getOtherTeamList(),
    });
}

function changePlayerType(select) {
    teamId = select.id.split('playerType')[1];

    if (select.value == 'Pitchers') {
        showType = 'pit';
        hideType = 'bat';
    } else {
        showType = 'bat';
        hideType = 'pit';
    }

    showTableId = 'table#' + showType + teamId;
    showTableTotalsId = showTableId + '-totals';
    hideTableId = 'table#' + hideType + teamId;
    hideTableTotalsId = hideTableId + '-totals';

    $(hideTableId).hide();
    $(hideTableTotalsId).hide();
    $(showTableId).show();
    $(showTableTotalsId).show();
}

function changeStatType(select) {
    teamId = select.id.split('statType')[1];

    if (select.value == 'Percentiles') {
        $('table#bat' + teamId).find('tr.team_raw').hide();
        $('table#pit' + teamId).find('tr.team_raw').hide();
        $('table#bat' + teamId + '-totals').find('tr.team_raw').hide();
        $('table#pit' + teamId + '-totals').find('tr.team_raw').hide();


        $('table#bat' + teamId).find('tr.team_percentile').show();
        $('table#pit' + teamId).find('tr.team_percentile').show();
        $('table#bat' + teamId + '-totals').find('tr.team_percentile').show();
        $('table#pit' + teamId + '-totals').find('tr.team_percentile').show();
    } else {
        $('table#bat' + teamId).find('tr.team_percentile').hide();
        $('table#pit' + teamId).find('tr.team_percentile').hide();
        $('table#bat' + teamId + '-totals').find('tr.team_percentile').hide();
        $('table#pit' + teamId + '-totals').find('tr.team_percentile').hide();

        $('table#bat' + teamId).find('tr.team_raw').show();
        $('table#pit' + teamId).find('tr.team_raw').show();
        $('table#bat' + teamId + '-totals').find('tr.team_raw').show();
        $('table#pit' + teamId + '-totals').find('tr.team_raw').show();
    }
}

ready = function() {
    $('body').addClass('stop-scrolling')

    restorePreviousSettings();

    changeDisplayedPlayersTable($('select#playersTable').get(0))
    setTeamHeaderScrolls();
    // document.getElementById('availablePlayersCumulativeTable').addEventListener('scroll', scrollHeader);

    $('table#myTeam').on('scroll', scrollTeamHeader);
    $('tr.team').hover(showRemovePlayerButton, hideRemovePlayerButton);

    initContextMenus();
}

document.addEventListener('turbolinks:load', ready);
