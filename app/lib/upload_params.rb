class UploadParams
  def initialize(params, use_nginx: true)
    @use_nginx = use_nginx
    @params = params
  end

  def original_filename(resource_name)
    @params["#{resource_name}_name"]
  end

  def upload_filepath(resource_name)
    if @use_nginx
      nginx_uploaded_file(resource_name)
    else
      rack_temporary_file(resource_name)
    end
  end

  private

  def nginx_uploaded_file(resource_name)
    @params["#{resource_name}_path"]
  end

  def rack_temporary_file(resource_name)
    resource_params = @params[resource_name]
    return unless resource_params.respond_to?(:[])

    tempfile = resource_params[:tempfile] || resource_params['tempfile']
    tempfile.respond_to?(:path) ? tempfile.path : tempfile
  end
end

