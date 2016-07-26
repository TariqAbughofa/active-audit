module ActiveAudit
  class AuditPusher < ActiveJob::Base

    def perform *args
      AuditRepository.create(args[0])
    end

  end
end
