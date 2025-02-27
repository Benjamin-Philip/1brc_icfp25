file = "data/wd-10K.txt"
versions = Ibrc.versions()

Enum.each(versions, fn version ->
  file = :eflambe.apply({Ibrc, :report, [version, file]}, return: :filename)
  File.rename!(file, "data/#{version}-eflambe-output.bggg")
end)
