import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    endpoint: String,
    refreshInterval: { type: Number, default: 30000 }
  }

  connect() {
    this.initializeChart()
    this.startRefresh()
  }

  disconnect() {
    this.stopRefresh()
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async initializeChart() {
    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element.querySelector("canvas")
    if (!canvas) return

    const endpoint = canvas.dataset.chartEndpoint
    if (!endpoint) return

    const data = await this.fetchData(endpoint)

    this.chart = new Chart(canvas, {
      type: "line",
      data: {
        labels: data.labels,
        datasets: [{
          label: "CPU %",
          data: data.values,
          borderColor: "rgb(239, 68, 68)",
          backgroundColor: "rgba(239, 68, 68, 0.1)",
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          x: { display: false },
          y: {
            display: false,
            min: 0,
            max: 100
          }
        },
        interaction: {
          intersect: false,
          mode: "index"
        }
      }
    })
  }

  async fetchData(endpoint) {
    try {
      const response = await fetch(endpoint)
      return await response.json()
    } catch (error) {
      console.error("Failed to fetch chart data:", error)
      return { labels: [], values: [] }
    }
  }

  startRefresh() {
    this.refreshTimer = setInterval(() => {
      this.refreshChart()
    }, this.refreshIntervalValue)
  }

  stopRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  async refreshChart() {
    if (!this.chart) return

    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element.querySelector("canvas")
    const endpoint = canvas?.dataset.chartEndpoint
    if (!endpoint) return

    const data = await this.fetchData(endpoint)

    this.chart.data.labels = data.labels
    this.chart.data.datasets[0].data = data.values
    this.chart.update("none")
  }
}
