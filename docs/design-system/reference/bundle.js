/* @ds-bundle: {"format":4,"namespace":"DnDisc","components":[{"name":"Button"},{"name":"Switch"},{"name":"Slider"},{"name":"SegmentedControl"},{"name":"Badge"},{"name":"SceneRow"},{"name":"SfxTile"},{"name":"AmbientRow"},{"name":"MusicCard"},{"name":"MixerBar"},{"name":"NavRail"},{"name":"Icon"},{"name":"Logo"},{"name":"Equalizer"},{"name":"SceneCover"},{"name":"TextField"},{"name":"Select"},{"name":"Checkbox"},{"name":"Dropzone"},{"name":"Chip"},{"name":"Dialog"},{"name":"Menu"},{"name":"Tooltip"},{"name":"Toast"},{"name":"ProgressBar"},{"name":"EmptyState"},{"name":"TrackRow"},{"name":"CatalogCard"},{"name":"ThemeCard"},{"name":"ShortcutRow"}]} */
(function () {
  var R = window.React, h = R.createElement, useState = R.useState;
  function cx() { return Array.prototype.slice.call(arguments).filter(Boolean).join(' '); }
  function P(d, extra) { return h('path', Object.assign({ d: d }, extra || {})); }
  var FILLED = { play: 1, pause: 1, stop: 1, bolt: 1, more: 1 };
  var ICONS = {
    play: [P('M8 5v14l11-7z')],
    pause: [P('M7 5h3.5v14H7zM13.5 5H17v14h-3.5z')],
    stop: [P('M7 7h10v10H7z')],
    plus: [P('M12 5v14M5 12h14')],
    x: [P('M6 6l12 12M18 6L6 18')],
    check: [P('M5 12.5l4.5 4.5L19 7')],
    'check-circle': [h('circle', { cx: 12, cy: 12, r: 9 }), P('M8 12.5l3 3 5-6')],
    search: [h('circle', { cx: 11, cy: 11, r: 6 }), P('M20 20l-4.2-4.2')],
    volume: [P('M4 10v4h4l5 4V6L8 10H4z'), P('M16 9a4 4 0 010 6M18.5 6.5a8 8 0 010 11')],
    mute: [P('M4 10v4h4l5 4V6L8 10H4z'), P('M17 9l5 5M22 9l-5 5')],
    more: [h('circle', { cx: 5, cy: 12, r: 1.6 }), h('circle', { cx: 12, cy: 12, r: 1.6 }), h('circle', { cx: 19, cy: 12, r: 1.6 })],
    pin: [P('M9 4h6l-1 6 3 3H7l3-3-1-6zM12 13v7')],
    bolt: [P('M13 3L5 14h6l-1 7 8-11h-6l1-7z')],
    music: [P('M9 18V6l10-2v12'), h('circle', { cx: 7, cy: 18, r: 2 }), h('circle', { cx: 17, cy: 16, r: 2 })],
    waves: [P('M3 9c3-3 6 3 9 0s6 3 9 0M3 15c3-3 6 3 9 0s6 3 9 0')],
    dashboard: [P('M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z')],
    library: [P('M5 4h4v16H5zM11 4h4v16h-4zM17 6.5l3 .8-3.2 12.7-2.8-.8z')],
    catalog: [P('M12 3l9 5-9 5-9-5 9-5zM3 13l9 5 9-5')],
    bundle: [P('M3 8l9-5 9 5v8l-9 5-9-5zM3 8l9 5 9-5M12 13v8')],
    settings: [P('M4 7h10M18 7h2M4 17h2M10 17h10'), h('circle', { cx: 16, cy: 7, r: 2 }), h('circle', { cx: 8, cy: 17, r: 2 })],
    scene: [P('M4 5h16v14H4zM4 15l4-4 4 3 3-2 5 4')],
    'panel-left': [P('M4 5h16v14H4zM9 5v14')],
    refresh: [P('M19.5 12a7.5 7.5 0 11-2.2-5.3'), P('M18 3.5v4h-4')],
    upload: [P('M12 16V4M7 9l5-5 5 5M5 20h14')],
    download: [P('M12 4v12M7 11l5 5 5-5M5 20h14')],
    archive: [P('M4 6h16v4H4zM6 10v10h12V10M10 14h4')],
    edit: [P('M4 20l1-4L16.5 4.5a2 2 0 013 3L8 19l-4 1zM14 7l3 3')],
    trash: [P('M5 7h14M10 7V4h4v3M7 7l1 13h8l1-13M10 11v5M14 11v5')],
    keyboard: [P('M5 6h14a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2z'), P('M7 10h.01M11 10h.01M15 10h.01M7 14h10')],
    palette: [P('M12 3a9 9 0 100 18c1.5 0 2-1 1.5-2.2-.5-1.3.3-2.8 1.8-2.8H18a3 3 0 003-3C21 7 17 3 12 3z'), P('M7.5 11h.01M10 7.5h.01M14.5 7.5h.01')],
    terminal: [P('M4 5h16v14H4zM7.5 10l3 2.5-3 2.5M13 15h4')],
    clock: [h('circle', { cx: 12, cy: 12, r: 9 }), P('M12 7v5l3 2')],
    alert: [P('M12 4l9 16H3z'), P('M12 10v4M12 17h.01')],
    info: [h('circle', { cx: 12, cy: 12, r: 9 }), P('M12 11v5M12 8h.01')],
    'chevron-down': [P('M6 9l6 6 6-6')],
    'chevron-right': [P('M9 6l6 6-6 6')],
    loop: [P('M17 3l3 3-3 3M20 6H8a4 4 0 00-4 4M7 21l-3-3 3-3M4 18h12a4 4 0 004-4')],
    door: [P('M6 21V10a6 6 0 0112 0v11M4 21h16'), h('circle', { cx: 15, cy: 14.5, r: 1, fill: 'currentColor', stroke: 'none' })],
    chains: [P('M10 14a3.5 3.5 0 005 0l3-3a3.5 3.5 0 00-5-5l-1 1M14 10a3.5 3.5 0 00-5 0l-3 3a3.5 3.5 0 005 5l1-1')],
    skull: [P('M12 3a7.5 7.5 0 00-4.5 13.5V20h9v-3.5A7.5 7.5 0 0012 3z'), h('circle', { cx: 9, cy: 11, r: 1.4 }), h('circle', { cx: 15, cy: 11, r: 1.4 }), P('M10.5 20v-2M13.5 20v-2')],
    growl: [P('M4 10v4M8 7v10M12 4v16M16 8v8M20 10v4')],
    stone: [P('M4 19l2-8 5-6 6 2 3 5-2 7z'), P('M11 5l1 6 4 2')],
    flame: [P('M12 3c.5 3.5 5 5 5 10a5 5 0 01-10 0c0-2.2 1-3.6 2.5-5 .2 1.8 1 2.6 2 3 .8-2.5.3-5.5.5-8z')],
    coins: [h('ellipse', { cx: 12, cy: 6.5, rx: 7, ry: 3 }), P('M5 6.5v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5M5 11.5v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5')],
    sword: [P('M20 4v5l-9 9-5-5 9-9h5z'), P('M5 15l4 4M3.5 20.5L7 17')],
    dragon: [P('M3 6c5 0 8 3 9 8 1-5 4-8 9-8-.5 4-2 7-5 9l-1.500-1-2.500 4.500-2.500-4.500-1.500 1C5.500 13 3.500 10 3 6z')],
    thunder: [P('M7 14h10a3.5 3.5 0 00.5-6.97 5.5 5.5 0 00-10.6-.3A3.8 3.8 0 007 14z'), P('M13 15l-2.5 3.5h3.5L11.5 22')],
    steps: [P('M7.5 3c1.8 0 2.6 2 2.6 4.5S9.300 11 7.500 11 4.900 10 4.900 7.500 5.700 3 7.500 3z'), h('circle', { cx: 7.5, cy: 14.5, r: 1.6 }), P('M16.5 9.500c1.800 0 2.600 2 2.600 4.500S18.300 17.500 16.500 17.500 13.900 16.500 13.900 14 14.700 9.500 16.500 9.500z'), h('circle', { cx: 16.5, cy: 21, r: 1.6 })],
    whisper: [P('M5 5h14v10h-7l-4 4v-4H5z'), P('M9 10h.01M12 10h.01M15 10h.01')],
    arrow: [P('M4 20L16 8M20 4l-2 6-4-4z'), P('M4 20l.5-5.500M4 20l5.500-.5M7 17l.5-4M7 17l4-.5')],
    shield: [P('M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6l7-3z'), P('M12 3v18')],
    spell: [P('M12 3c.7 4.5 1.5 5.3 6 6-4.5.7-5.3 1.5-6 6-.7-4.5-1.5-5.3-6-6 4.5-.7 5.3-1.5 6-6z'), P('M19 16v4M17 18h4')],
    potion: [P('M10 3h4M10.5 3v5L5.5 18a2 2 0 001.8 3h9.4a2 2 0 001.8-3L13.5 8V3'), P('M8 15h8')],
    rain: [P('M7 14h10a3.5 3.5 0 00.5-6.97 5.5 5.5 0 00-10.6-.3A3.8 3.8 0 007 14z'), P('M8 17.5l-1 3M12 17.5l-1 3M16 17.5l-1 3')],
    wind: [P('M3 9h10a2.5 2.5 0 10-2.5-2.5M3 13h14a2.5 2.5 0 11-2.5 2.5M3 17h6')],
    forest: [P('M8 20v-3M8 4l-4 7h2.5L4 16h8l-2.5-5H12L8 4z'), P('M17 20v-2M17 8l-3 5h2l-2.5 5h7L16 13h2L17 8z')],
    campfire: [P('M12 3c.5 3 4 4 4 8a4 4 0 01-8 0c0-1.6.8-2.8 2-3.8.2 1.4.8 2 1.5 2.3.5-2 .3-4 .5-6.5z'), P('M4 20l16-3M4 17l16 3')],
    sea: [P('M3 7c3-3 6 3 9 0s6 3 9 0M3 12c3-3 6 3 9 0s6 3 9 0M3 17c3-3 6 3 9 0s6 3 9 0')],
    cave: [P('M3 20h18M5 20v-8a7 7 0 0114 0v8'), P('M12 9c1 1.6 2 2.6 2 3.8a2 2 0 01-4 0c0-1.2 1-2.2 2-3.8z')],
    tavern: [P('M5 8h10v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8z'), P('M15 10h2a2 2 0 010 5h-2'), P('M5 8a2.5 2.5 0 012.5-3 2.5 2.5 0 014.5-.5A2.5 2.5 0 0115 8')],
    night: [P('M20 14.5A8 8 0 019.5 4a8 8 0 1010.5 10.5z'), P('M17 4v3M15.5 5.5h3')],
    crowd: [h('circle', { cx: 9, cy: 8, r: 3 }), P('M3.5 20v-1.5a5.5 5.5 0 0111 0V20'), h('circle', { cx: 17, cy: 9, r: 2.4 }), P('M16.5 14a4.5 4.5 0 014.5 4.5V20')],
    swamp: [h('ellipse', { cx: 8, cy: 8, rx: 1.6, ry: 3.5 }), P('M8 11.5V18'), h('ellipse', { cx: 15, cy: 6, rx: 1.6, ry: 3.5 }), P('M15 9.5V16'), P('M3 20c1.5-1 3-1 4.5 0s3 1 4.5 0 3-1 4.5 0 3 1 4.5 0')],
    birds: [P('M3 10c2.2-3 4.3-3 6.5 0 2.2-3 4.3-3 6.5 0'), P('M10 17c1.5-2 3-2 4.5 0 1.5-2 3-2 4.5 0')],
    snow: [P('M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9')]
  };
  var COVERS = {
    peaks: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzFkMmEzMyIvPjxjaXJjbGUgY3g9IjExODAiIGN5PSIxMjAiIHI9IjcwIiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjkyIi8+PHBvbHlnb24gcG9pbnRzPSIwLDQwMCAwLDI3MCAyMjAsMTcwIDQyMCwyNjAgNjQwLDEyMCA5MDAsMzAwIDExNjAsMjAwIDE0MDAsMjkwIDE2MDAsMjEwIDE2MDAsNDAwIiBmaWxsPSIjMmM0MTUwIi8+PHBvbHlnb24gcG9pbnRzPSIwLDQwMCAwLDMzMCAzMDAsMjUwIDU2MCwzNDAgODYwLDIzMCAxMTgwLDM1MCAxNDIwLDI3MCAxNjAwLDM0MCAxNjAwLDQwMCIgZmlsbD0iIzFhMjgzMCIvPjwvc3ZnPg==',
    tower: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzJhMjAzMCIvPjxjaXJjbGUgY3g9IjQyMCIgY3k9IjI1MCIgcj0iMTUwIiBmaWxsPSIjYzk4YTZiIiBvcGFjaXR5PSIwLjg1Ii8+PHBhdGggZD0iTTAgNDAwVjMzMFEzMDAgMjcwIDcwMCAzMjBUMTYwMCAzMDBWNDAwWiIgZmlsbD0iIzFjMTUyMCIvPjxyZWN0IHg9IjEwNDAiIHk9IjE1MCIgd2lkdGg9IjQ2IiBoZWlnaHQ9IjE3NSIgZmlsbD0iIzEyMGQxNiIvPjxwb2x5Z29uIHBvaW50cz0iMTAzMCwxNTAgMTA2Myw5OCAxMDk2LDE1MCIgZmlsbD0iIzEyMGQxNiIvPjxyZWN0IHg9IjEwNTciIHk9IjE5MCIgd2lkdGg9IjEyIiBoZWlnaHQ9IjIyIiBmaWxsPSIjZTliMjdhIi8+PC9zdmc+',
    forest: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzFmMmIyNSIvPjxwb2x5Z29uIHBvaW50cz0iLTc1LDMwMCAtMTAsMTQ1IDU1LDMwMCIgZmlsbD0iIzJiM2QzMyIvPjxwb2x5Z29uIHBvaW50cz0iMzYsMzAwIDk1LDE1OCAxNTQsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSI4OSwzMDAgMTc0LDk2IDI1OSwzMDAiIGZpbGw9IiMyYjNkMzMiLz48cG9seWdvbiBwb2ludHM9IjIwMCwzMDAgMjc2LDExOCAzNTIsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSIzNDcsMzAwIDQwNywxNTcgNDY3LDMwMCIgZmlsbD0iIzJiM2QzMyIvPjxwb2x5Z29uIHBvaW50cz0iNDQ0LDMwMCA1MjgsMTAwIDYxMiwzMDAiIGZpbGw9IiMyYjNkMzMiLz48cG9seWdvbiBwb2ludHM9IjUyNSwzMDAgNTgzLDE2MCA2NDEsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSI1OTUsMzAwIDY3NSwxMDkgNzU1LDMwMCIgZmlsbD0iIzJiM2QzMyIvPjxwb2x5Z29uIHBvaW50cz0iNzM2LDMwMCA3OTYsMTU2IDg1NiwzMDAiIGZpbGw9IiMyYjNkMzMiLz48cG9seWdvbiBwb2ludHM9IjgyNCwzMDAgODg1LDE1MyA5NDYsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSI5MjYsMzAwIDEwMDUsMTEwIDEwODQsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSIxMDEwLDMwMCAxMDczLDE0OSAxMTM2LDMwMCIgZmlsbD0iIzJiM2QzMyIvPjxwb2x5Z29uIHBvaW50cz0iMTE2MiwzMDAgMTIzMCwxMzYgMTI5OCwzMDAiIGZpbGw9IiMyYjNkMzMiLz48cG9seWdvbiBwb2ludHM9IjEyNTAsMzAwIDEzMTAsMTU3IDEzNzAsMzAwIiBmaWxsPSIjMmIzZDMzIi8+PHBvbHlnb24gcG9pbnRzPSIxMzI4LDMwMCAxNDA2LDExNCAxNDg0LDMwMCIgZmlsbD0iIzJiM2QzMyIvPjxwb2x5Z29uIHBvaW50cz0iMTQwNSwzMDAgMTQ3MywxMzYgMTU0MSwzMDAiIGZpbGw9IiMyYjNkMzMiLz48cmVjdCB4PSIwIiB5PSIyMDAiIHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjkwIiBmaWxsPSIjMmQzZjM1IiBvcGFjaXR5PSIwLjU1Ii8+PHBvbHlnb24gcG9pbnRzPSItMTQyLDQwMCAtMzUsMTQ1IDcyLDQwMCIgZmlsbD0iIzE0MWQxOCIvPjxwb2x5Z29uIHBvaW50cz0iMzAsNDAwIDEyMiwxNzkgMjE0LDQwMCIgZmlsbD0iIzE0MWQxOCIvPjxwb2x5Z29uIHBvaW50cz0iMjE5LDQwMCAzMDMsMTk4IDM4Nyw0MDAiIGZpbGw9IiMxNDFkMTgiLz48cG9seWdvbiBwb2ludHM9IjM4Miw0MDAgNDY1LDIwMSA1NDgsNDAwIiBmaWxsPSIjMTQxZDE4Ii8+PHBvbHlnb24gcG9pbnRzPSI1MjEsNDAwIDYxNCwxNzcgNzA3LDQwMCIgZmlsbD0iIzE0MWQxOCIvPjxwb2x5Z29uIHBvaW50cz0iNjQ1LDQwMCA3NTgsMTI5IDg3MSw0MDAiIGZpbGw9IiMxNDFkMTgiLz48cG9seWdvbiBwb2ludHM9Ijc3Myw0MDAgODU1LDIwMyA5MzcsNDAwIiBmaWxsPSIjMTQxZDE4Ii8+PHBvbHlnb24gcG9pbnRzPSI5NDUsNDAwIDEwNTIsMTQzIDExNTksNDAwIiBmaWxsPSIjMTQxZDE4Ii8+PHBvbHlnb24gcG9pbnRzPSIxMDUwLDQwMCAxMTQ3LDE2OSAxMjQ0LDQwMCIgZmlsbD0iIzE0MWQxOCIvPjxwb2x5Z29uIHBvaW50cz0iMTE3NSw0MDAgMTI4MSwxNDYgMTM4Nyw0MDAiIGZpbGw9IiMxNDFkMTgiLz48cG9seWdvbiBwb2ludHM9IjEzMTUsNDAwIDE0MjIsMTQ0IDE1MjksNDAwIiBmaWxsPSIjMTQxZDE4Ii8+PHJlY3QgeD0iMCIgeT0iMzgwIiB3aWR0aD0iMTYwMCIgaGVpZ2h0PSIyMCIgZmlsbD0iIzE0MWQxOCIvPjwvc3ZnPg==',
    sea: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzFiMjc0MCIvPjxjbGlwUGF0aCBpZD0iYyI+PHJlY3Qgd2lkdGg9IjE2MDAiIGhlaWdodD0iMjUwIi8+PC9jbGlwUGF0aD48ZyBjbGlwLXBhdGg9InVybCgjYykiPjxjaXJjbGUgY3g9IjgwMCIgY3k9IjI1MCIgcj0iOTIiIGZpbGw9IiNlNmE4NmMiLz48L2c+PHJlY3QgeD0iMCIgeT0iMjUwIiB3aWR0aD0iMTYwMCIgaGVpZ2h0PSIxNTAiIGZpbGw9IiMxNDIwM2EiLz48cmVjdCB4PSI3MTUiIHk9IjI2MiIgd2lkdGg9IjE3MCIgaGVpZ2h0PSI2IiBmaWxsPSIjZTZhODZjIiBvcGFjaXR5PSIwLjU1Ii8+PHJlY3QgeD0iNzM1IiB5PSIyNzgiIHdpZHRoPSIxMzAiIGhlaWdodD0iNiIgZmlsbD0iI2U2YTg2YyIgb3BhY2l0eT0iMC41NSIvPjxyZWN0IHg9Ijc1MiIgeT0iMjk2IiB3aWR0aD0iOTYiIGhlaWdodD0iNiIgZmlsbD0iI2U2YTg2YyIgb3BhY2l0eT0iMC41NSIvPjxyZWN0IHg9Ijc3MCIgeT0iMzE2IiB3aWR0aD0iNjAiIGhlaWdodD0iNiIgZmlsbD0iI2U2YTg2YyIgb3BhY2l0eT0iMC41NSIvPjxwb2x5Z29uIHBvaW50cz0iMTEyMCwyMzIgMTEyMCwxNzYgMTE2MCwyMzIiIGZpbGw9IiMwZTE2MjYiLz48cGF0aCBkPSJNMTEwMCAyMzJIMTE4MEwxMTY2IDI0NEgxMTE0WiIgZmlsbD0iIzBlMTYyNiIvPjwvc3ZnPg==',
    gate: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzFiMTkxNyIvPjxyZWN0IHg9IjAiIHk9IjM2MCIgd2lkdGg9IjE2MDAiIGhlaWdodD0iNDAiIGZpbGw9IiMxNDExMGYiLz48cGF0aCBkPSJNNjAwIDQwMFYyMDBhMjAwIDIwMCAwIDAgMSA0MDAgMFY0MDBaIiBmaWxsPSIjMmEyNjIyIi8+PHBhdGggZD0iTTY1MCA0MDBWMjAwYTE1MCAxNTAgMCAwIDEgMzAwIDBWNDAwWiIgZmlsbD0iIzNhMzIyYSIvPjxwYXRoIGQ9Ik03MDAgNDAwVjIwMGExMDAgMTAwIDAgMCAxIDIwMCAwVjQwMFoiIGZpbGw9IiM2YjRmMzMiLz48cGF0aCBkPSJNNzUwIDQwMFYyMDVhNTAgNTAgMCAwIDEgMTAwIDBWNDAwWiIgZmlsbD0iI2UwYTk2YSIvPjxyZWN0IHg9Ijc0MCIgeT0iMzgwIiB3aWR0aD0iMTIwIiBoZWlnaHQ9IjEwIiBmaWxsPSIjNmI0ZjMzIi8+PC9zdmc+',
    dunes: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzNhMmEyNCIvPjxjaXJjbGUgY3g9IjExNTAiIGN5PSIxNDAiIHI9IjgwIiBmaWxsPSIjZjBjNDhhIi8+PHBhdGggZD0iTTAgNDAwVjI4MFEzMDAgMjAwIDYyMCAyNzBUMTIwMCAyNTBUMTYwMCAyODBWNDAwWiIgZmlsbD0iIzhhNWEzZSIvPjxwYXRoIGQ9Ik0wIDQwMFYzMzBRNDAwIDI1MCA4MDAgMzIwVDE2MDAgMzEwVjQwMFoiIGZpbGw9IiM2YTQyMzEiLz48cGF0aCBkPSJNMCA0MDBWMzcyUTUwMCAzMjAgOTAwIDM2NVQxNjAwIDM2MFY0MDBaIiBmaWxsPSIjNDcyOTFmIi8+PC9zdmc+',
    village: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAwIDQwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgc2xpY2UiPjxyZWN0IHdpZHRoPSIxNjAwIiBoZWlnaHQ9IjQwMCIgZmlsbD0iIzE1MWEzMyIvPjxjaXJjbGUgY3g9IjUwNyIgY3k9IjE2NiIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIyODciIGN5PSIxMDkiIHI9IjIuNSIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iOTkwIiBjeT0iMTYzIiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjEyNjAiIGN5PSIxOCIgcj0iMiIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iNTUxIiBjeT0iMTU2IiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjQxMiIgY3k9IjEzNSIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxMTQ1IiBjeT0iMTM2IiByPSIyIiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxMzI4IiBjeT0iNTMiIHI9IjEuNSIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iMTMyMCIgY3k9IjUzIiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjgxOCIgY3k9IjE4IiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjE1MSIgY3k9IjU1IiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjEwNyIgY3k9IjkyIiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjU3MSIgY3k9IjEzNiIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxNDkyIiBjeT0iMTE0IiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9Ijg5NCIgY3k9IjExNiIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxMjAxIiBjeT0iMTI4IiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9Ijc2OCIgY3k9IjM5IiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjI5OCIgY3k9IjE0MSIgcj0iMS41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSI1NDgiIGN5PSIxMjYiIHI9IjIuNSIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iNjM2IiBjeT0iMTIyIiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjgxMCIgY3k9IjE2MSIgcj0iMiIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iMTExMyIgY3k9IjE2NCIgcj0iMiIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iMTIxNiIgY3k9Ijc0IiByPSIyIiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxNDE2IiBjeT0iMjIiIHI9IjIiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjEyNjAiIGN5PSI1NiIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSI2ODgiIGN5PSIxNTMiIHI9IjIuNSIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iMTE4NSIgY3k9IjQxIiByPSIyLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjEzNjIiIGN5PSI2OSIgcj0iMi41IiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxMTk0IiBjeT0iODMiIHI9IjIiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjI3NCIgY3k9IjMxIiByPSIyIiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIxMzI4IiBjeT0iMTM4IiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjcyNCIgY3k9IjMyIiByPSIyIiBmaWxsPSIjZThkY2M0IiBvcGFjaXR5PSIwLjgiLz48Y2lyY2xlIGN4PSIzMjgiIGN5PSIyMCIgcj0iMiIgZmlsbD0iI2U4ZGNjNCIgb3BhY2l0eT0iMC44Ii8+PGNpcmNsZSBjeD0iODk0IiBjeT0iMTIxIiByPSIxLjUiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOCIvPjxjaXJjbGUgY3g9IjE0MDAiIGN5PSI5MCIgcj0iMzgiIGZpbGw9IiNlOGRjYzQiIG9wYWNpdHk9IjAuOTUiLz48Y2lyY2xlIGN4PSIxNDE4IiBjeT0iODAiIHI9IjM0IiBmaWxsPSIjMTUxYTMzIi8+PHBhdGggZD0iTTAgNDAwVjMyMFE0MDAgMjcwIDgwMCAzMjBUMTYwMCAzMTBWNDAwWiIgZmlsbD0iIzBlMTIyNiIvPjxyZWN0IHg9IjMwMCIgeT0iMjcwIiB3aWR0aD0iNzAiIGhlaWdodD0iMTMwIiBmaWxsPSIjMGEwZDFjIi8+PHBvbHlnb24gcG9pbnRzPSIyOTIsMjcwIDMzNS4wLDIzNS4wIDM3OCwyNzAiIGZpbGw9IiMwYTBkMWMiLz48cmVjdCB4PSIzMjEuMCIgeT0iMjk3LjAiIHdpZHRoPSIxNS40IiBoZWlnaHQ9IjE1LjQiIGZpbGw9IiNlOWIyN2EiLz48cmVjdCB4PSI0MzAiIHk9IjI2MCIgd2lkdGg9IjkwIiBoZWlnaHQ9IjE1MCIgZmlsbD0iIzBhMGQxYyIvPjxwb2x5Z29uIHBvaW50cz0iNDIyLDI2MCA0NzUuMCwyMTUuMCA1MjgsMjYwIiBmaWxsPSIjMGEwZDFjIi8+PHJlY3QgeD0iNDU3LjAiIHk9IjI5Ni4wIiB3aWR0aD0iMTkuOCIgaGVpZ2h0PSIxOS44IiBmaWxsPSIjZTliMjdhIi8+PHJlY3QgeD0iOTgwIiB5PSIyNjUiIHdpZHRoPSI4MCIgaGVpZ2h0PSIxNDAiIGZpbGw9IiMwYTBkMWMiLz48cG9seWdvbiBwb2ludHM9Ijk3MiwyNjUgMTAyMC4wLDIyNS4wIDEwNjgsMjY1IiBmaWxsPSIjMGEwZDFjIi8+PHJlY3QgeD0iMTAwNC4wIiB5PSIyOTYuNSIgd2lkdGg9IjE3LjYiIGhlaWdodD0iMTcuNiIgZmlsbD0iI2U5YjI3YSIvPjxyZWN0IHg9IjExMjAiIHk9IjI1NSIgd2lkdGg9IjEwMCIgaGVpZ2h0PSIxNjAiIGZpbGw9IiMwYTBkMWMiLz48cG9seWdvbiBwb2ludHM9IjExMTIsMjU1IDExNzAuMCwyMDUuMCAxMjI4LDI1NSIgZmlsbD0iIzBhMGQxYyIvPjxyZWN0IHg9IjExNTAuMCIgeT0iMjk1LjUiIHdpZHRoPSIyMi4wIiBoZWlnaHQ9IjIyLjAiIGZpbGw9IiNlOWIyN2EiLz48cmVjdCB4PSIxMjgwIiB5PSIyNzMiIHdpZHRoPSI2NCIgaGVpZ2h0PSIxMjIiIGZpbGw9IiMwYTBkMWMiLz48cG9seWdvbiBwb2ludHM9IjEyNzIsMjczIDEzMTIuMCwyNDEuMCAxMzUyLDI3MyIgZmlsbD0iIzBhMGQxYyIvPjxyZWN0IHg9IjEyOTkuMiIgeT0iMjk2LjQiIHdpZHRoPSIxNC4wOCIgaGVpZ2h0PSIxNC4wOCIgZmlsbD0iI2U5YjI3YSIvPjwvc3ZnPg=='
  };
  var COVER_IDS = ["peaks", "tower", "forest", "sea", "gate", "dunes", "village"];
  function Icon(p) {
    var s = p.size || 20, filled = FILLED[p.name];
    return h('svg', { className: 'dd-icon', width: s, height: s, viewBox: '0 0 24 24', fill: filled ? 'currentColor' : 'none', stroke: 'currentColor', strokeWidth: filled ? 1.5 : 1.75, strokeLinecap: 'round', strokeLinejoin: 'round', 'aria-hidden': true }, ICONS[p.name]);
  }

  function Logo(p) {
    var s = p.size || 32, small = s < 24;
    return h('span', { className: cx('dd-logo', p.className), role: 'img', 'aria-label': 'DnDisc' },
      h('svg', { width: s, height: s, viewBox: '0 0 100 100', fill: 'none', 'aria-hidden': true },
        h('path', { d: 'M16 12 H46 A38 38 0 0 1 46 88 H16 Z', stroke: 'currentColor', strokeWidth: small ? 7 : 5, strokeLinejoin: 'round' }),
        small ? null : h('path', { d: 'M30 28 H46 A22 22 0 0 1 46 72 H30 Z', stroke: 'currentColor', strokeWidth: 2.5, strokeLinejoin: 'round', opacity: 0.5 }),
        h('circle', { cx: 46, cy: 50, r: small ? 8 : 6, fill: 'var(--primary)' })),
      p.wordmark ? h('span', { className: 'dd-logo__word', style: { fontSize: Math.round(s * 0.56) } }, 'DnDisc') : null);
  }

  function Equalizer(p) {
    var n = p.bars || 4, lv = p.levels, bars = [];
    for (var i = 0; i < n; i++) bars.push(h('i', { key: i, style: lv ? { '--lv': Math.max(0.12, Math.min(1, lv[i % lv.length] || 0)) } : { '--i': i, '--lv': 0.2 + ((i * 37) % 60) / 100 } }));
    return h('span', { className: cx('dd-eq', p.className), 'data-active': !!p.active, 'data-live': lv ? 'true' : undefined, 'aria-hidden': true, style: { '--eq-h': (p.height || 16) + 'px' } }, bars);
  }

  function hashStr(s) { var x = 2166136261; s = String(s); for (var i = 0; i < s.length; i++) { x ^= s.charCodeAt(i); x = Math.imul(x, 16777619); } return Math.abs(x); }
  function SceneCover(p) {
    var src = null;
    if (p.src) src = p.src;
    else if (p.cover && COVERS[p.cover]) src = COVERS[p.cover];
    else src = COVERS[COVER_IDS[hashStr(p.seed == null ? 'dndisc' : p.seed) % COVER_IDS.length]];
    var dim = p.dim == null ? 0 : p.dim;
    function px(v) { return /^[0-9.]+$/.test(String(v)) ? v + 'px' : v; }
    var st = { backgroundImage: 'url("' + src + '")', '--dim': dim + '%' };
    if (p.fill) { st.position = 'absolute'; st.inset = 0; }
    if (p.height != null) st.height = px(p.height);
    if (p.width != null) st.width = px(p.width);
    if (p.radius != null) st.borderRadius = px(p.radius);
    if (p.style && typeof p.style === 'object') Object.assign(st, p.style);
    return h('div', { className: cx('dd-cover', p.className), 'aria-hidden': true, style: st });
  }

  function Button(p) {
    var variant = p.variant || 'secondary', iconOnly = !!p.iconOnly;
    var cls = cx('dd-btn', 'dd-btn--' + variant, p.size === 'lg' && 'dd-btn--lg', iconOnly && 'dd-btn--icon', p.className);
    return h('button', { type: 'button', className: cls, disabled: p.disabled, onClick: p.onClick, 'aria-label': iconOnly ? p.label : undefined, title: iconOnly ? p.label : undefined },
      p.icon ? h(Icon, { name: p.icon, size: variant === 'transport' ? 24 : 20 }) : null,
      iconOnly ? null : p.children,
      p.hotkey ? h('span', { className: 'dd-kbd' }, p.hotkey) : null);
  }

  function Switch(p) {
    return h('button', { type: 'button', role: 'switch', 'aria-checked': !!p.checked, 'aria-label': p.label, className: cx('dd-switch', p.className), onClick: function () { p.onChange && p.onChange(!p.checked); } });
  }

  function Slider(p) {
    var min = p.min == null ? 0 : p.min, max = p.max == null ? 100 : p.max;
    var pct = ((p.value - min) / (max - min)) * 100;
    return h('div', { className: cx('dd-slider', p.className) },
      p.icon ? h(Icon, { name: p.icon, size: 18 }) : null,
      p.label ? h('span', { className: 'dd-slider__label' }, p.label) : null,
      h('input', { type: 'range', min: min, max: max, value: p.value, 'aria-label': p.ariaLabel || p.label, style: { '--fill': pct + '%' }, onChange: function (e) { p.onChange && p.onChange(Number(e.target.value)); } }),
      p.showValue === false ? null : h('span', { className: 'dd-slider__value' }, (p.format ? p.format(p.value) : Math.round(p.value) + '%')));
  }

  function SegmentedControl(p) {
    return h('div', { className: cx('dd-seg', p.className), role: 'radiogroup', 'aria-label': p.label },
      p.options.map(function (o) {
        return h('button', { key: o.id, type: 'button', role: 'radio', 'aria-checked': p.value === o.id, className: 'dd-seg__item', style: o.color ? { '--c': o.color } : null, onClick: function () { p.onChange && p.onChange(o.id); } },
          o.color ? h('span', { className: 'dd-seg__dot' }) : null,
          o.label,
          o.key ? h('span', { className: 'dd-seg__key' }, o.key) : null);
      }));
  }

  function Badge(p) {
    return h('span', { className: cx('dd-badge', p.tone && p.tone !== 'neutral' && 'dd-badge--' + p.tone, p.dot && 'dd-badge--dot', p.className) }, p.children);
  }

  function SceneRow(p) {
    var hasCover = p.cover || p.src || p.seed != null;
    return h('button', { type: 'button', className: cx('dd-scene', p.className), 'aria-current': !!p.active, onClick: p.onClick },
      h('span', { className: 'dd-scene__thumb' }, hasCover ? h(SceneCover, { cover: p.cover, src: p.src, seed: p.seed, className: 'dd-scene__cover' }) : h(Icon, { name: 'scene', size: 20 })),
      h('span', { className: 'dd-scene__body' }, h('div', { className: 'dd-scene__name' }, p.name), p.meta ? h('div', { className: 'dd-scene__meta' }, p.meta) : null),
      p.active ? h('span', { className: 'dd-scene__live', title: 'Active' }, h(Equalizer, { active: p.playing !== false, bars: 3, height: 14 })) : null);
  }

  function SfxTile(p) {
    if (p.empty) return h('button', { type: 'button', className: cx('dd-sfx', 'dd-sfx--empty', p.className), 'aria-label': p.label || 'Add sound', onClick: p.onClick }, h(Icon, { name: 'plus', size: 24 }));
    return h('button', { type: 'button', className: cx('dd-sfx', p.className), 'data-playing': !!p.playing, onClick: p.onClick },
      p.playing ? h(Equalizer, { className: 'dd-sfx__key', active: true, bars: 3, height: 14 }) : (p.hotkey ? h('span', { className: 'dd-kbd dd-sfx__key' }, p.hotkey) : null),
      h('span', { className: 'dd-sfx__icon' }, h(Icon, { name: p.icon || 'bolt', size: 24 })),
      h('span', { className: 'dd-sfx__label' }, p.label),
      p.playing ? h('span', { className: 'dd-sfx__bar', style: { '--p': (p.progress || 0) + '%' } }) : null);
  }

  function AmbientRow(p) {
    return h('div', { className: cx('dd-amb', p.className), 'data-on': !!p.on },
      h('button', { type: 'button', className: 'dd-amb__toggle', 'aria-pressed': !!p.on, 'aria-label': p.name, title: p.on ? 'On' : 'Off', onClick: function () { p.onToggle && p.onToggle(!p.on); } }, h(Icon, { name: p.icon || 'waves', size: 22 })),
      h('div', { className: 'dd-amb__name' }, p.pinned ? h('span', { className: 'dd-amb__pin', title: 'Pinned' }, h(Icon, { name: 'pin', size: 16 })) : null, h('span', null, p.name), p.on ? h(Equalizer, { active: true, bars: 3, height: 14 }) : null),
      h(Slider, { value: p.volume, onChange: p.onVolume, ariaLabel: p.name + ' volume' }),
      h(Button, { variant: 'ghost', icon: 'more', iconOnly: true, label: 'More' }));
  }

  function Panel(p) {
    return h('section', { className: cx('dd-panel', p.className) },
      p.title ? h('header', { className: 'dd-panel__head' }, p.icon ? h(Icon, { name: p.icon, size: 20 }) : null, h('h3', { className: 'dd-panel__title' }, p.title), p.actions) : null,
      p.children);
  }

  function fmt(t) { var m = Math.floor(t / 60), s = Math.floor(t % 60); return m + ':' + (s < 10 ? '0' : '') + s; }
  function MusicCard(p) {
    var st = useState(p.position == null ? 62 : p.position), pos = st[0], setPos = st[1];
    var total = p.duration || 214, playing = !!p.playing;
    return h(Panel, { title: 'Music', icon: 'music', className: p.className, actions: h(Badge, { tone: playing ? 'primary' : 'neutral', dot: true }, playing ? 'Playing' : 'Paused') },
      h('p', { className: 'dd-music__track' }, p.track),
      h(Equalizer, { className: 'dd-eq--wide', active: playing, bars: 48, height: 28, levels: p.levels }),
      h('div', { className: 'dd-music__row' },
        h(Button, { variant: 'transport', icon: playing ? 'pause' : 'play', iconOnly: true, label: playing ? 'Pause' : 'Play', onClick: p.onToggle }),
        h(Button, { variant: 'ghost', icon: 'stop', iconOnly: true, label: 'Stop' }),
        h('span', { className: 'dd-music__time' }, fmt(pos)),
        h(Slider, { value: pos, min: 0, max: total, showValue: false, ariaLabel: 'Position', onChange: setPos, className: 'dd-slider--grow' }),
        h('span', { className: 'dd-music__time' }, fmt(total))));
  }

  function MixerBar(p) {
    var init = {}; (p.channels || []).forEach(function (c) { init[c.id] = c.value; });
    var st = useState(init), vals = st[0], setVals = st[1];
    var playing = !!p.playing;
    function chan(c) { return h(Slider, { key: c.id, icon: c.icon, value: vals[c.id], ariaLabel: c.label, onChange: function (v) { var n = Object.assign({}, vals); n[c.id] = v; setVals(n); } }); }
    var chs = p.channels || [], master = chs.filter(function (c) { return c.id === 'master'; }), rest = chs.filter(function (c) { return c.id !== 'master'; });
    return h('div', { className: cx('dd-mixer', p.className) },
      h('div', { className: 'dd-mixer__now' }, h('span', { className: 'dd-mixer__art' }, h(Icon, { name: 'music', size: 20 })), h('div', { style: { minWidth: 0 } }, h('div', { className: 'dd-mixer__title' }, p.track), h('div', { className: 'dd-mixer__status' }, h(Equalizer, { active: playing, bars: 4, height: 12 }), playing ? 'Playing' : 'Paused'))),
      h('div', { className: 'dd-mixer__transport' }, h(Button, { variant: 'transport', icon: playing ? 'pause' : 'play', iconOnly: true, label: playing ? 'Pause' : 'Play', onClick: p.onToggle }), h(Button, { variant: 'ghost', icon: 'stop', iconOnly: true, label: 'Stop' })),
      h('div', { className: 'dd-mixer__channels' }, rest.map(chan), master.length ? h('span', { className: 'dd-mixer__sep' }) : null, master.map(chan)));
  }

  function NavRail(p) {
    var items = p.items || [];
    return h('nav', { className: cx('dd-nav', p.open && 'dd-nav--open', p.className), 'aria-label': 'Main' },
      items.map(function (it) { return h('button', { key: it.id, type: 'button', className: 'dd-nav__item', 'aria-current': p.active === it.id ? 'page' : undefined, title: it.label, onClick: function () { p.onSelect && p.onSelect(it.id); } }, h(Icon, { name: it.icon }), p.open ? it.label : null); }));
  }

  // ---- Inputs ----
  function useCtl(p, key, dflt) {
    var st = useState(p['default' + key.charAt(0).toUpperCase() + key.slice(1)] != null ? p['default' + key.charAt(0).toUpperCase() + key.slice(1)] : dflt);
    var ctl = p[key] !== undefined;
    return [ctl ? p[key] : st[0], function (v) { if (!ctl) st[1](v); }];
  }
  function fieldId(p) { return p.id || ('dd-f-' + String(p.label || p.placeholder || 'field').replace(/[^A-Za-z0-9]+/g, '-').toLowerCase()); }

  function TextField(p) {
    var c = useCtl(p, 'value', ''), val = c[0], id = fieldId(p);
    function set(v) { c[1](v); p.onChange && p.onChange(v); }
    return h('div', { className: cx('dd-field', p.error && 'dd-field--error', p.disabled && 'dd-field--disabled', p.className), style: p.width ? { width: p.width } : null },
      p.label ? h('label', { className: 'dd-field__label', htmlFor: id }, p.label) : null,
      h('div', { className: 'dd-field__box' },
        p.icon ? h('span', { className: 'dd-field__icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
        h('input', { id: id, type: p.type || 'text', value: val, placeholder: p.placeholder, disabled: p.disabled, 'aria-invalid': p.error ? true : undefined, onChange: function (e) { set(e.target.value); } }),
        p.clearable && val ? h('button', { type: 'button', className: 'dd-field__clear', 'aria-label': 'Clear', onClick: function () { set(''); } }, h(Icon, { name: 'x', size: 16 })) : null,
        p.hotkey && !val ? h('span', { className: 'dd-kbd' }, p.hotkey) : null),
      p.error ? h('div', { className: 'dd-field__msg dd-field__msg--error' }, p.error) : (p.hint ? h('div', { className: 'dd-field__msg' }, p.hint) : null));
  }

  function Select(p) {
    var opts = p.options || [], c = useCtl(p, 'value', opts.length ? opts[0].id : ''), id = fieldId(p);
    return h('div', { className: cx('dd-field', p.disabled && 'dd-field--disabled', p.className), style: p.width ? { width: p.width } : null },
      p.label ? h('label', { className: 'dd-field__label', htmlFor: id }, p.label) : null,
      h('div', { className: 'dd-field__box dd-select' },
        p.icon ? h('span', { className: 'dd-field__icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
        h('select', { id: id, value: c[0], disabled: p.disabled, onChange: function (e) { c[1](e.target.value); p.onChange && p.onChange(e.target.value); } },
          opts.map(function (o) { return h('option', { key: o.id, value: o.id }, o.label); })),
        h('span', { className: 'dd-select__chev' }, h(Icon, { name: 'chevron-down', size: 16 }))),
      p.hint ? h('div', { className: 'dd-field__msg' }, p.hint) : null);
  }

  function Checkbox(p) {
    var c = useCtl(p, 'checked', false), on = !!c[0];
    return h('button', { type: 'button', role: 'checkbox', 'aria-checked': on, disabled: p.disabled, className: cx('dd-check', p.className), onClick: function () { c[1](!on); p.onChange && p.onChange(!on); } },
      h('span', { className: 'dd-check__box' }, on ? h(Icon, { name: 'check', size: 14 }) : null),
      h('span', { className: 'dd-check__text' }, h('span', { className: 'dd-check__label' }, p.label), p.description ? h('span', { className: 'dd-check__desc' }, p.description) : null));
  }

  function Dropzone(p) {
    var st = useState(false), over = p.active != null ? !!p.active : st[0];
    return h('div', { className: cx('dd-drop', p.compact && 'dd-drop--compact', p.className), 'data-over': over, role: 'button', tabIndex: 0,
      onClick: p.onBrowse, onDragOver: function (e) { e.preventDefault(); st[1](true); }, onDragLeave: function () { st[1](false); },
      onDrop: function (e) { e.preventDefault(); st[1](false); p.onFiles && p.onFiles(e.dataTransfer.files); } },
      h('span', { className: 'dd-drop__icon' }, h(Icon, { name: 'upload', size: 24 })),
      h('span', { className: 'dd-drop__text' },
        h('span', { className: 'dd-drop__title' }, over ? (p.overTitle || 'Release to import') : (p.title || 'Drop audio files here')),
        h('span', { className: 'dd-drop__hint' }, p.hint || 'or click to browse · MP3, OGG, FLAC, WAV')));
  }

  function Chip(p) {
    var inner = [p.icon ? h(Icon, { key: 'i', name: p.icon, size: 14 }) : null, h('span', { key: 'l' }, p.label),
      p.onRemove ? h('button', { key: 'x', type: 'button', className: 'dd-chip__x', 'aria-label': 'Remove ' + p.label, onClick: function (e) { e.stopPropagation(); p.onRemove(); } }, h(Icon, { name: 'x', size: 14 })) : null];
    if (p.onClick) return h('button', { type: 'button', className: cx('dd-chip', 'dd-chip--btn', p.className), 'aria-pressed': !!p.selected, onClick: p.onClick }, inner);
    return h('span', { className: cx('dd-chip', p.selected && 'dd-chip--on', p.className) }, inner);
  }

  // ---- Overlays & status ----
  function actionNodes(list) {
    return (list || []).map(function (a, i) { return R.isValidElement(a) ? a : h(Button, { key: i, variant: a.variant || 'secondary', icon: a.icon, onClick: a.onClick, disabled: a.disabled }, a.label); });
  }
  function Dialog(p) {
    if (p.open === false) return null;
    var panel = h('div', { className: cx('dd-dialog', p.size === 'lg' && 'dd-dialog--lg', p.size === 'sm' && 'dd-dialog--sm', p.className), role: 'dialog', 'aria-modal': true, 'aria-label': p.title },
      h('header', { className: 'dd-dialog__head' },
        p.icon ? h('span', { className: cx('dd-dialog__icon', p.tone === 'danger' && 'dd-dialog__icon--danger') }, h(Icon, { name: p.icon, size: 20 })) : null,
        h('div', { className: 'dd-dialog__titles' }, h('h2', { className: 'dd-dialog__title' }, p.title), p.description ? h('p', { className: 'dd-dialog__desc' }, p.description) : null),
        h(Button, { variant: 'ghost', icon: 'x', iconOnly: true, label: 'Close', onClick: p.onClose })),
      p.children ? h('div', { className: 'dd-dialog__body' }, p.children) : null,
      p.actions ? h('footer', { className: 'dd-dialog__foot' }, p.footNote ? h('span', { className: 'dd-dialog__note' }, p.footNote) : null, actionNodes(p.actions)) : null);
    if (p.inline) return panel;
    return h('div', { className: 'dd-scrim', onClick: function (e) { if (e.target === e.currentTarget && p.onClose) p.onClose(); } }, panel);
  }

  function Menu(p) {
    return h('div', { className: cx('dd-menu', p.className), role: 'menu', 'aria-label': p.label },
      (p.items || []).map(function (it, i) {
        if (it.separator) return h('div', { key: 's' + i, className: 'dd-menu__sep', role: 'separator' });
        return h('button', { key: it.id || i, type: 'button', role: it.checked != null ? 'menuitemcheckbox' : 'menuitem', 'aria-checked': it.checked != null ? !!it.checked : undefined, disabled: it.disabled,
          className: cx('dd-menu__item', it.danger && 'dd-menu__item--danger'), onClick: function () { p.onSelect && p.onSelect(it.id); } },
          it.icon ? h(Icon, { name: it.icon, size: 18 }) : h('span', { className: 'dd-menu__pad' }),
          h('span', { className: 'dd-menu__label' }, it.label),
          it.hotkey ? h('span', { className: 'dd-kbd' }, it.hotkey) : null,
          it.checked ? h(Icon, { name: 'check', size: 16 }) : null);
      }));
  }

  function Tooltip(p) {
    return h('span', { className: cx('dd-tip', p.open && 'dd-tip--open', p.className) }, p.children,
      h('span', { className: cx('dd-tip__bubble', 'dd-tip__bubble--' + (p.placement || 'top')), role: 'tooltip' }, p.label, p.hotkey ? h('span', { className: 'dd-tip__key' }, p.hotkey) : null));
  }

  function ProgressBar(p) {
    var ind = p.value == null || p.value === '';
    var v = ind ? 0 : Math.max(0, Math.min(100, Number(p.value)));
    return h('div', { className: cx('dd-progress', p.className) },
      p.label ? h('div', { className: 'dd-progress__row' }, h('span', null, p.label), !ind && p.showValue !== false ? h('span', { className: 'dd-progress__val' }, Math.round(v) + '%') : null) : null,
      h('div', { className: 'dd-progress__track', role: 'progressbar', 'aria-label': p.label || 'Progress', 'aria-valuemin': 0, 'aria-valuemax': 100, 'aria-valuenow': ind ? undefined : v },
        h('div', { className: cx('dd-progress__fill', ind && 'dd-progress__fill--ind'), style: ind ? null : { width: v + '%' } })),
      p.caption ? h('div', { className: 'dd-progress__cap' }, p.caption) : null);
  }

  function Toast(p) {
    var tone = p.tone || 'neutral';
    var ic = p.icon || (tone === 'success' ? 'check-circle' : tone === 'danger' ? 'alert' : 'info');
    return h('div', { className: cx('dd-toast', 'dd-toast--' + tone, p.className), role: tone === 'danger' ? 'alert' : 'status' },
      h('span', { className: 'dd-toast__icon' }, h(Icon, { name: ic, size: 20 })),
      h('div', { className: 'dd-toast__body' }, h('div', { className: 'dd-toast__title' }, p.title), p.message ? h('div', { className: 'dd-toast__msg' }, p.message) : null,
        p.progress != null ? h(ProgressBar, { value: p.progress, className: 'dd-toast__progress' }) : null),
      p.action ? h(Button, { variant: 'ghost', onClick: p.action.onClick }, p.action.label) : null,
      p.closable !== false ? h(Button, { variant: 'ghost', icon: 'x', iconOnly: true, label: 'Dismiss', onClick: p.onClose }) : null);
  }

  function EmptyState(p) {
    return h('div', { className: cx('dd-empty', p.tone === 'danger' && 'dd-empty--danger', p.className) },
      h('span', { className: 'dd-empty__icon' }, h(Icon, { name: p.icon || (p.tone === 'danger' ? 'alert' : 'search'), size: 24 })),
      h('div', { className: 'dd-empty__title' }, p.title),
      p.message ? h('p', { className: 'dd-empty__msg' }, p.message) : null,
      p.action ? h(Button, { variant: p.action.variant || 'secondary', icon: p.action.icon, onClick: p.action.onClick }, p.action.label) : null);
  }

  // ---- Library, Catalog, Settings ----
  var KINDS = { music: { icon: 'music', label: 'Music' }, ambient: { icon: 'waves', label: 'Ambient' }, sfx: { icon: 'bolt', label: 'SFX' } };
  function TrackRow(p) {
    var k = KINDS[p.kind] || KINDS.music;
    var meta = [k.label, p.duration, p.meta].filter(Boolean).join(' · ');
    return h('div', { className: cx('dd-track', p.playing && 'dd-track--playing', p.missing && 'dd-track--missing', p.className), title: p.path },
      h('span', { className: 'dd-track__icon' }, p.playing ? h(Equalizer, { active: true, bars: 3, height: 14 }) : h(Icon, { name: p.icon || k.icon, size: 20 })),
      h('div', { className: 'dd-track__body' }, h('div', { className: 'dd-track__title' }, p.title), h('div', { className: 'dd-track__meta' }, meta)),
      p.tags && p.tags.length ? h('div', { className: 'dd-track__tags' }, p.tags.slice(0, 3).map(function (t) { return h(Chip, { key: t, label: t }); })) : null,
      p.missing ? h(Badge, { tone: 'danger', dot: true }, 'File missing') : null,
      h('div', { className: 'dd-track__actions' },
        h(Button, { variant: 'ghost', icon: p.playing ? 'stop' : 'play', iconOnly: true, label: p.playing ? 'Stop preview' : 'Preview', onClick: p.onPlay, disabled: p.missing }),
        h(Button, { variant: 'ghost', icon: 'edit', iconOnly: true, label: 'Edit', onClick: p.onEdit }),
        h(Button, { variant: 'ghost', icon: 'more', iconOnly: true, label: 'More', onClick: p.onMore })));
  }

  var CAT = { scene: { icon: 'scene', label: 'Scene' }, media: { icon: 'music', label: 'Media pack' }, bundle: { icon: 'bundle', label: 'Bundle' } };
  function CatalogCard(p) {
    var k = CAT[p.kind] || CAT.scene, s = p.status || 'available', foot;
    if (s === 'installed') foot = [h('span', { key: 's', className: 'dd-cat__state' }, h(Icon, { name: 'check-circle', size: 16 }), 'Installed'), h(Button, { key: 'm', variant: 'ghost', icon: 'more', iconOnly: true, label: 'More' })];
    else if (s === 'downloading') foot = h(ProgressBar, { value: p.progress || 0, label: 'Downloading', className: 'dd-cat__progress' });
    else foot = [p.size ? h('span', { key: 'z', className: 'dd-cat__size' }, p.size) : h('span', { key: 'z' }), h(Button, { key: 'b', variant: s === 'update' ? 'primary' : 'secondary', icon: s === 'update' ? 'refresh' : 'download', onClick: p.onAction }, s === 'update' ? 'Update' : 'Install')];
    return h('article', { className: cx('dd-cat', p.className), 'data-status': s },
      h(SceneCover, { cover: p.cover, src: p.src, seed: p.seed || p.title, className: 'dd-cat__cover' }),
      h('div', { className: 'dd-cat__body' },
        h('div', { className: 'dd-cat__kind' }, h(Icon, { name: k.icon, size: 16 }), h('span', null, k.label + (p.count ? ' · ' + p.count : ''))),
        h('h3', { className: 'dd-cat__title' }, p.title),
        p.author ? h('div', { className: 'dd-cat__author' }, p.author) : null,
        p.description ? h('p', { className: 'dd-cat__desc' }, p.description) : null),
      h('div', { className: 'dd-cat__foot' }, foot));
  }

  function ThemeCard(p) {
    if (p.add) return h('button', { type: 'button', className: cx('dd-theme', 'dd-theme--add', p.className), onClick: p.onClick }, h(Icon, { name: 'plus', size: 20 }), h('span', null, p.name || 'Create theme'));
    var c = p.colors || {};
    return h('button', { type: 'button', className: cx('dd-theme', p.className), 'aria-pressed': !!p.selected, onClick: p.onClick },
      h('span', { className: 'dd-theme__preview', style: { background: c.bg } },
        h('span', { className: 'dd-theme__panel', style: { background: c.surface } },
          h('span', { className: 'dd-theme__line', style: { background: c.text } }),
          h('span', { className: 'dd-theme__line dd-theme__line--short', style: { background: c.text } }),
          h('span', { className: 'dd-theme__accent', style: { background: c.primary } }))),
      h('span', { className: 'dd-theme__foot' }, h('span', { className: 'dd-theme__name' }, p.name),
        p.custom ? h('span', { className: 'dd-theme__tag' }, 'Custom') : null,
        p.selected ? h(Icon, { name: 'check-circle', size: 16 }) : null));
  }

  function ShortcutRow(p) {
    var keys = p.keys || [], out = [];
    keys.forEach(function (k, i) { if (i) out.push(h('span', { key: 'o' + i, className: 'dd-short__or' }, 'or')); out.push(h('kbd', { key: 'k' + i, className: 'dd-kbd' }, k)); });
    return h('div', { className: cx('dd-short', p.className) },
      h('div', { className: 'dd-short__text' }, h('div', { className: 'dd-short__action' }, p.action), p.description ? h('div', { className: 'dd-short__desc' }, p.description) : null),
      h('div', { className: 'dd-short__keys' }, out),
      p.onEdit !== undefined || p.editable ? h(Button, { variant: 'ghost', icon: 'edit', iconOnly: true, label: 'Change shortcut', onClick: p.onEdit }) : null);
  }

  window.DnDisc = { Icon: Icon, Logo: Logo, Equalizer: Equalizer, SceneCover: SceneCover, Button: Button, Switch: Switch, Slider: Slider, SegmentedControl: SegmentedControl, Badge: Badge, SceneRow: SceneRow, SfxTile: SfxTile, AmbientRow: AmbientRow, Panel: Panel, MusicCard: MusicCard, MixerBar: MixerBar, NavRail: NavRail, TextField: TextField, Select: Select, Checkbox: Checkbox, Dropzone: Dropzone, Chip: Chip, Dialog: Dialog, Menu: Menu, Tooltip: Tooltip, Toast: Toast, ProgressBar: ProgressBar, EmptyState: EmptyState, TrackRow: TrackRow, CatalogCard: CatalogCard, ThemeCard: ThemeCard, ShortcutRow: ShortcutRow };
})();
