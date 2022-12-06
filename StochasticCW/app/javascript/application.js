// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "chartkick"
import "Chart.bundle"

const input_n = document.getElementById('n')
const input_v = document.getElementById('v')
const input_a = document.getElementById('a')
const input_b = document.getElementById('b')
const input_w = document.getElementById('w')

const button_start = document.getElementById('btn-start')
const button_dl = document.getElementById('btn-dl')
const div_charts = document.getElementById('charts')
const progress_bar = document.getElementById('progress-bar')
const checkbox_chart_type = document.getElementById('chart-type')

const checkbox_inv = document.getElementById('checkbox-inv')
const checkbox_neu = document.getElementById('checkbox-neu')
const checkbox_met = document.getElementById('checkbox-met')

const box_table = document.getElementById('box-table')
const table_mean_variance = document.getElementById('table-mean-variance')

let data_seed

function parse_parameters() {
    let n = input_n.value
    let a = input_a.value
    let b = input_b.value
    let v = input_v.value
    let w = input_w.value

    if (a > b) {
        [a, b] = [b, a]

        input_a.value = a
        input_b.value = b
    }

    if (n <= 0 || v <= 0 || w <= 0) {
        M.toast({html: 'Wrong input.', classes: 'red accent-3 rounded'});

        return;
    }

    return `n=${n}&a=${a}&b=${b}&v=${v}&w=${w}&methods=${checkbox_met.checked << 2 | checkbox_neu.checked << 1 | checkbox_inv.checked}`;
}

function refill_table(table, w, h, f) {
    table.innerHTML = ''

    for (let y = 0; y < h; ++y) {
        let tr = table.insertRow();
        for (let x = 0; x < w; ++x) {
            let td = tr.insertCell()

            let t = f(x, y, td)

            if (t instanceof Node) {
                td.appendChild(t)
            } else {
                td.innerHTML = t
            }

            tr.appendChild(td)
        }
        table.appendChild(tr)
    }
}

function refill_table_with_header_row_and_col(table, title, hr, hc, f) {
    refill_table(table, hr.length + 1, hc.length + 1, (x, y, td) => {
        if (x === 0 && y === 0) return title

        if (y === 0) return hr[x - 1]
        if (x === 0) return hc[y - 1]

        return f(x - 1, y - 1, td)
    })
}

function updateTable(mean_and_variance) {
    let names = Object.keys(mean_and_variance)

    let data = names.map((name) => mean_and_variance[name])

    refill_table_with_header_row_and_col(table_mean_variance, '', ['Mean', 'Variance'], names, (x, y) => data[y][x])
}

button_start.addEventListener('click', () => {
    let parameters = parse_parameters()

    if (parameters === undefined) return

    progress_bar.classList.remove('hide')

    $.get(`charts?${parameters}`)
        .done((data) => {
            Chartkick.eachChart((chart) => {
                chart.updateData(data['data'])
                data_seed = data['seed']

                updateTable(data['mean_and_variance'])

                progress_bar.classList.add('hide')
                div_charts.classList.remove('hide')
                box_table.classList.remove('hide')
                button_dl.classList.remove('disabled')
            })
        })
        .fail(() => {
            M.toast({html: 'Error.', classes: 'red accent-3 rounded'});
            progress_bar.classList.add('hide')
        })
})

checkbox_chart_type.addEventListener('click', () => {
    let c1 = document.getElementById('chart-1')
    let c2 = document.getElementById('chart-2')

    if (checkbox_chart_type.checked) {
        [c1, c2] = [c2, c1]
    }

    c1.classList.remove('hide')
    c2.classList.add('hide')
})

function on_method_checkbox_click() {
    if (checkbox_inv.checked + checkbox_neu.checked + checkbox_met.checked) {
        button_start.classList.remove('disabled')
    } else {
        button_start.classList.add('disabled')
    }
}

checkbox_inv.addEventListener('click', on_method_checkbox_click)
checkbox_neu.addEventListener('click', on_method_checkbox_click)
checkbox_met.addEventListener('click', on_method_checkbox_click)

input_v.addEventListener('change', () => {
    if ([1, 2, 4].includes(+input_v.value)) {
        if (checkbox_inv.hasAttribute('disabled')) {
            checkbox_inv.removeAttribute('disabled')
            checkbox_inv.checked = true
        }
    } else {
        checkbox_inv.checked = false
        checkbox_inv.setAttribute('disabled', 'disabled')
    }

    on_method_checkbox_click()
})

button_dl.addEventListener('click', () => {
    let parameters = parse_parameters()

    if (parameters === undefined) return

    window.location.replace(`csv?${parameters}&seed=${data_seed}`)
})
