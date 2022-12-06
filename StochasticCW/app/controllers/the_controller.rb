require 'csv'

class TheController < ApplicationController
  def index; end

  def charts
    srand
    seed = Random::DEFAULT.seed.to_s

    raw = TheHelper.calc_chart_data(params[:n].to_i, params[:a].to_f..params[:b].to_f, params[:v].to_f,
                                    params.fetch(:w, 0.1).to_f, params.fetch(:methods, 0b111).to_i)

    data = raw.map { |t| t.merge({ data: TheHelper.bins(t[:data]) }) }

    mean_and_variance = TheHelper.calc_mean_and_variance params[:v].to_f, raw

    render json: { data:, seed:, mean_and_variance: }
  end

  def csv
    srand params[:seed].to_i

    raw = TheHelper.calc_chart_data(params[:n].to_i, params[:a].to_f..params[:b].to_f, params[:v].to_f,
                                    params.fetch(:w, 0.1).to_f, params.fetch(:methods, 0b111).to_i)

    @data = raw

    respond_to do |format|
      format.csv do
        response.header['Content-Type'] = 'text/csv'
        response.header['Content-Disposition'] = 'attachment;filename=data.csv'
        render template: 'the/data'
      end
    end
  end
end
