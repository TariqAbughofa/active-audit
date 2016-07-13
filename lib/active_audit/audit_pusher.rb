module ActiveAudit
  class AuditPusher < ActiveJob::Base
    queue_as ActiveAudit.job_queue

    def perform *args
      AuditRepository.create(args[0])
    end

  end
end
